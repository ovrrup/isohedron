import 'package:test/test.dart';
import 'package:isohedron/models/task_filter.dart';
import 'package:isohedron/models/task_item.dart';
import 'package:isohedron/models/task_list.dart';
import 'package:isohedron/services/storage_service.dart';

void main() {
  group('StorageService', () {
    late StorageService storage;

    setUp(() async {
      storage = StorageService.inMemory();
      await storage.init();
    });

    test('initializes with default local task list', () async {
      final lists = await storage.getTaskLists();
      expect(lists.length, 1);
      expect(lists.first.id, 'local_default');
      expect(lists.first.title, 'My Tasks');
      expect(lists.first.isLocal, isTrue);

      final selectedId = await storage.getSelectedTaskListId();
      expect(selectedId, 'local_default');
    });

    test('can switch and persist selected task list', () async {
      const newList = TaskList(
        id: 'work_list',
        title: 'Work',
        isDefault: false,
        isLocal: false,
      );

      final currentLists = await storage.getTaskLists();
      await storage.saveTaskLists([...currentLists, newList]);
      await storage.setSelectedTaskListId('work_list');

      final selected = await storage.getSelectedTaskListId();
      expect(selected, 'work_list');
    });

    test('CRUD operations for tasks', () async {
      final task1 = TaskItem(
        id: 't-1',
        taskListId: 'local_default',
        title: 'Prepare presentation',
        notes: 'Review slides with team',
        updatedAt: DateTime.now(),
      );

      await storage.upsertTask(task1);
      var tasks = await storage.getTasks('local_default');
      expect(tasks.length, 1);
      expect(tasks.first.title, 'Prepare presentation');

      // Update task
      final updatedTask = task1.copyWith(isCompleted: true);
      await storage.upsertTask(updatedTask);
      tasks = await storage.getTasks('local_default');
      expect(tasks.length, 1);
      expect(tasks.first.isCompleted, isTrue);

      // Delete task
      await storage.deleteTask('local_default', 't-1');
      tasks = await storage.getTasks('local_default');
      expect(tasks, isEmpty);
    });

    test('filterTasks correctly filters by status and search query', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 12, 0);

      final taskActive = TaskItem(
        id: '1',
        taskListId: 'local_default',
        title: 'Normal active task',
        updatedAt: now,
      );

      final taskToday = TaskItem(
        id: '2',
        taskListId: 'local_default',
        title: 'Task due today',
        due: today,
        updatedAt: now,
      );

      final taskPlanned = TaskItem(
        id: '3',
        taskListId: 'local_default',
        title: 'Task planned for evening',
        plannedTime: today.add(const Duration(hours: 4)),
        updatedAt: now,
      );

      final taskCompleted = TaskItem(
        id: '4',
        taskListId: 'local_default',
        title: 'Finished homework',
        isCompleted: true,
        updatedAt: now,
      );

      final taskCancelled = TaskItem(
        id: '5',
        taskListId: 'local_default',
        title: 'Skipped workout',
        isCancelled: true,
        cancelReason: 'Too tired',
        updatedAt: now,
      );

      final allTasks = [
        taskActive,
        taskToday,
        taskPlanned,
        taskCompleted,
        taskCancelled,
      ];

      // All filter (active items)
      final all = storage.filterTasks(allTasks, TaskFilter.all);
      expect(all.map((t) => t.id), containsAll(['1', '2', '3']));
      expect(all.map((t) => t.id), isNot(contains('4')));
      expect(all.map((t) => t.id), isNot(contains('5')));

      // Today filter
      final dueToday = storage.filterTasks(allTasks, TaskFilter.today);
      expect(dueToday.map((t) => t.id), containsAll(['2', '3']));

      // Timezone normalization test: UTC midnight due date
      final utcMidnightTask = TaskItem(
        id: 'utc-today',
        taskListId: 'local_default',
        title: 'UTC Midnight Task',
        due: DateTime.utc(now.year, now.month, now.day),
        updatedAt: now,
      );
      final utcFiltered = storage.filterTasks([utcMidnightTask], TaskFilter.today);
      expect(utcFiltered.length, 1);

      // Planned filter
      final planned = storage.filterTasks(allTasks, TaskFilter.planned);
      expect(planned.map((t) => t.id), contains('3'));

      // Completed filter
      final completed = storage.filterTasks(allTasks, TaskFilter.completed);
      expect(completed.map((t) => t.id), equals(['4']));

      // Cancelled filter
      final cancelled = storage.filterTasks(allTasks, TaskFilter.cancelled);
      expect(cancelled.map((t) => t.id), equals(['5']));

      // Search query filtering
      final searched = storage.filterTasks(
        allTasks,
        TaskFilter.all,
        searchQuery: 'workout',
      );
      // Cancelled task contains workout but filter is all (active)
      expect(searched, isEmpty);

      final searchedCancelled = storage.filterTasks(
        allTasks,
        TaskFilter.cancelled,
        searchQuery: 'tired',
      );
      expect(searchedCancelled.length, 1);
      expect(searchedCancelled.first.id, '5');
    });

    test('persists and clears Google auth token and email', () async {
      expect(await storage.getGoogleAccessToken(), isNull);
      expect(await storage.getGoogleUserEmail(), isNull);

      await storage.saveGoogleAuth(
        token: 'ya29.sample_test_token',
        email: 'user@example.com',
      );

      expect(await storage.getGoogleAccessToken(), 'ya29.sample_test_token');
      expect(await storage.getGoogleUserEmail(), 'user@example.com');

      await storage.clearGoogleAuth();
      expect(await storage.getGoogleAccessToken(), isNull);
      expect(await storage.getGoogleUserEmail(), isNull);
    });

    test('replaces local task ID with remote task item without duplicates', () async {
      final localTask = TaskItem(
        id: 'local_task_12345',
        taskListId: 'local_default',
        title: 'Draft proposal',
        updatedAt: DateTime.now(),
      );

      await storage.upsertTask(localTask);
      expect((await storage.getTasks('local_default')).length, 1);

      final remoteTask = TaskItem(
        id: 'gtasks_remote_98765',
        taskListId: 'local_default',
        title: 'Draft proposal',
        updatedAt: DateTime.now(),
      );

      await storage.replaceTaskId('local_task_12345', remoteTask);
      final tasks = await storage.getTasks('local_default');
      expect(tasks.length, 1);
      expect(tasks.first.id, 'gtasks_remote_98765');
    });

    test('records deletion tombstones for remote IDs but skips ephemeral local IDs', () async {
      // Local ephemeral task
      await storage.deleteTask('local_default', 'local_task_ephemeral');
      expect(storage.getDeletedTaskIds(), isNot(contains('local_task_ephemeral')));

      // Remote task
      await storage.deleteTask('local_default', 'remote_gtask_123');
      expect(storage.getDeletedTaskIds(), contains('remote_gtask_123'));

      // Purge tombstone
      await storage.purgeDeletedTaskId('remote_gtask_123');
      expect(storage.getDeletedTaskIds(), isNot(contains('remote_gtask_123')));
    });

    test('creates and deletes task lists with cascade cleanup', () async {
      final created = await storage.createTaskList('Project Falcon');
      expect(created.title, 'Project Falcon');
      expect((await storage.getTaskLists()).any((l) => l.id == created.id), isTrue);

      final task = TaskItem(
        id: 'task-in-falcon',
        taskListId: created.id,
        title: 'Classified task',
        updatedAt: DateTime.now(),
      );
      await storage.upsertTask(task);
      expect((await storage.getTasks(created.id)).length, 1);

      await storage.deleteTaskList(created.id);
      expect((await storage.getTaskLists()).any((l) => l.id == created.id), isFalse);
      expect(await storage.getTasks(created.id), isEmpty);
    });

    test('manages and persists hasCompletedOnboarding flag', () async {
      expect(storage.hasCompletedOnboarding, isFalse);

      await storage.setHasCompletedOnboarding(true);
      expect(storage.hasCompletedOnboarding, isTrue);

      await storage.setHasCompletedOnboarding(false);
      expect(storage.hasCompletedOnboarding, isFalse);
    });
  });
}

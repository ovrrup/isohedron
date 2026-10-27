import 'package:flutter_test/flutter_test.dart';
import 'package:isohedron/controllers/isohedron_app_controller.dart';
import 'package:isohedron/models/task_filter.dart';
import 'package:isohedron/models/task_list.dart';
import 'package:isohedron/services/google_tasks_service.dart';
import 'package:isohedron/services/notification_service.dart';
import 'package:isohedron/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IsohedronAppController', () {
    late StorageService storage;
    late NotificationService notifications;
    late GoogleTasksService googleTasks;
    late IsohedronAppController controller;

    setUp(() async {
      storage = StorageService.inMemory();
      notifications = NotificationService.inMemory();
      googleTasks = GoogleTasksService.mock(
        mockEmail: 'tester@example.com',
        initialLists: [
          const TaskList(
            id: 'g-list-1',
            title: 'Google Tasks Work',
            isDefault: false,
            isLocal: false,
          ),
        ],
      );

      controller = IsohedronAppController(
        storage: storage,
        notifications: notifications,
        googleTasks: googleTasks,
      );

      await controller.init();
    });

    test('initial state and default list setup', () {
      expect(controller.isInitialized, isTrue);
      expect(controller.currentFilter, TaskFilter.all);
      expect(controller.selectedListId, 'local_default');
      expect(controller.currentList.title, 'My Tasks');
      expect(controller.visibleTasks, isEmpty);
      expect(controller.overdueTasks, isEmpty);
    });

    test('notifies listeners when creating, completing, and deleting tasks', () async {
      int notifyCount = 0;
      controller.addListener(() {
        notifyCount++;
      });

      // 1. Create task
      final created = await controller.createTask(
        title: 'Complete tax report',
        notes: 'Gather all receipts',
      );

      expect(notifyCount, greaterThan(0));
      expect(controller.visibleTasks.length, 1);
      expect(controller.visibleTasks.first.id, created.id);

      // 2. Complete task
      final prevCount = notifyCount;
      await controller.completeTask(created.id);
      expect(notifyCount, greaterThan(prevCount));
      // In TaskFilter.all (active only), completed task is hidden
      expect(controller.visibleTasks, isEmpty);

      // Switch to completed filter
      controller.setFilter(TaskFilter.completed);
      expect(controller.visibleTasks.length, 1);
      expect(controller.visibleTasks.first.isCompleted, isTrue);

      // 3. Reopen task
      await controller.reopenTask(created.id);
      controller.setFilter(TaskFilter.all);
      expect(controller.visibleTasks.length, 1);
      expect(controller.visibleTasks.first.isCompleted, isFalse);

      // 4. Delete task
      await controller.deleteTask(created.id);
      expect(controller.visibleTasks, isEmpty);
    });

    test('detects overdue tasks and handles reflection reschedule', () async {
      final pastTime = DateTime.now().subtract(const Duration(hours: 2));

      final overdueTask = await controller.createTask(
        title: 'Review pull request',
        plannedTime: pastTime,
      );

      expect(controller.overdueTasks.length, 1);
      expect(controller.overdueTasks.first.id, overdueTask.id);

      // Reschedule task
      final futureTime = DateTime.now().add(const Duration(hours: 3));
      await controller.rescheduleTask(overdueTask.id, futureTime);

      expect(controller.overdueTasks, isEmpty);
      expect(controller.visibleTasks.first.plannedTime, futureTime);
    });

    test('handles cancel with reflection reason', () async {
      final task = await controller.createTask(
        title: 'Morning jog',
        notes: '5km park run',
      );

      await controller.cancelTask(task.id, reason: 'Thunderstorm');

      controller.setFilter(TaskFilter.cancelled);
      expect(controller.visibleTasks.length, 1);
      final cancelled = controller.visibleTasks.first;
      expect(cancelled.isCancelled, isTrue);
      expect(cancelled.cancelReason, 'Thunderstorm');
    });

    test('switches and creates task lists', () async {
      final createdList = await controller.createTaskList('Side Projects');
      expect(controller.selectedListId, createdList.id);
      expect(controller.currentList.title, 'Side Projects');

      await controller.switchList('local_default');
      expect(controller.selectedListId, 'local_default');
    });

    test('manages onboarding state and notifies listeners', () async {
      expect(controller.hasCompletedOnboarding, isFalse);

      bool notified = false;
      controller.addListener(() {
        notified = true;
      });

      await controller.completeOnboarding();
      expect(controller.hasCompletedOnboarding, isTrue);
      expect(notified, isTrue);

      await controller.resetOnboarding();
      expect(controller.hasCompletedOnboarding, isFalse);
    });
  });
}

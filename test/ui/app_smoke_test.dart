import 'package:test/test.dart';
import 'package:isohedron/models/task_filter.dart';
import 'package:isohedron/models/task_list.dart';
import 'package:isohedron/services/google_tasks_service.dart';
import 'package:isohedron/services/notification_service.dart';
import 'package:isohedron/services/storage_service.dart';
import 'package:isohedron/ui/home_screen.dart';

void main() {
  group('IsohedronAppController Smoke Test', () {
    late StorageService storage;
    late NotificationService notificationService;
    late GoogleTasksService googleTasksService;
    late IsohedronAppController appController;
    late MockNotificationAdapter mockNotifications;

    setUp(() async {
      storage = StorageService.inMemory();
      mockNotifications = MockNotificationAdapter();
      notificationService = NotificationService(adapter: mockNotifications);
      googleTasksService = GoogleTasksService.mock(
        mockEmail: 'alex@example.com',
        initialLists: [
          const TaskList(
            id: 'g-default',
            title: 'Google Tasks',
            isDefault: true,
            isLocal: false,
          ),
        ],
      );

      appController = IsohedronAppController(
        storage: storage,
        notifications: notificationService,
        googleTasks: googleTasksService,
      );

      await appController.init();
    });

    test('initializes with default local task list and active filter', () {
      expect(appController.currentFilter, TaskFilter.all);
      expect(appController.currentList.id, 'local_default');
      expect(appController.currentList.isLocal, isTrue);
      expect(appController.visibleTasks, isEmpty);
    });

    test('adds task with planned reminder and schedules notification', () async {
      final planned = DateTime.now().add(const Duration(hours: 3));
      final task = await appController.createTask(
        title: 'Draft quarterly report',
        notes: 'Include Q3 metrics',
        plannedTime: planned,
      );

      expect(task.title, 'Draft quarterly report');
      expect(task.plannedTime, planned);
      expect(appController.visibleTasks.length, 1);

      // Verify notification adapter received the scheduled reminder
      expect(mockNotifications.scheduled.length, 1);
      expect(mockNotifications.scheduled.first.title, contains('Draft quarterly report'));
    });

    test('marks task completed and clears scheduled reminder', () async {
      final planned = DateTime.now().add(const Duration(hours: 2));
      final task = await appController.createTask(
        title: 'Team sync',
        plannedTime: planned,
      );

      expect(mockNotifications.scheduled.length, 1);

      await appController.completeTask(task.id);

      // Under 'all' (active) filter, completed task is hidden
      expect(appController.visibleTasks, isEmpty);

      // Under 'completed' filter, task is visible
      appController.setFilter(TaskFilter.completed);
      expect(appController.visibleTasks.length, 1);
      expect(appController.visibleTasks.first.isCompleted, isTrue);

      // Notification is cancelled
      expect(mockNotifications.scheduled, isEmpty);
    });

    test('cancels task with reflection reason prompt and stores reason', () async {
      final task = await appController.createTask(
        title: 'Run 5 kilometers',
        plannedTime: DateTime.now().add(const Duration(hours: 1)),
      );

      await appController.cancelTask(
        task.id,
        reason: 'Heavy thunderstorm outside',
      );

      // Active list has no tasks
      expect(appController.visibleTasks, isEmpty);

      // Switch to cancelled filter tab
      appController.setFilter(TaskFilter.cancelled);
      expect(appController.visibleTasks.length, 1);
      final cancelled = appController.visibleTasks.first;
      expect(cancelled.isCancelled, isTrue);
      expect(cancelled.cancelReason, 'Heavy thunderstorm outside');
    });

    test('completing a previously cancelled task clears cancellation reason', () async {
      final task = await appController.createTask(title: 'Reactivated task');
      await appController.cancelTask(task.id, reason: 'Deferred');

      // Now mark completed
      await appController.completeTask(task.id);
      final completed = (await storage.getTasks('local_default')).firstWhere((t) => t.id == task.id);

      expect(completed.isCompleted, isTrue);
      expect(completed.isCancelled, isFalse);
      expect(completed.cancelReason, isNull);
    });

    test('syncCurrentList does not throw on network error', () async {
      await appController.signInGoogle();
      // Even if network throws, controller handles it gracefully
      await expectLater(appController.syncCurrentList(), completes);
    });
  });
}

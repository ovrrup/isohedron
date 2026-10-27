import 'package:flutter_test/flutter_test.dart';
import 'package:isohedron/controllers/isohedron_app_controller.dart';
import 'package:isohedron/models/task_filter.dart';
import 'package:isohedron/services/notification_service.dart';
import 'package:isohedron/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IsohedronAppController (Pure Sovereign Offline)', () {
    late StorageService storage;
    late NotificationService notifications;
    late IsohedronAppController controller;

    setUp(() async {
      storage = StorageService.inMemory();
      notifications = NotificationService.inMemory();

      controller = IsohedronAppController(
        storage: storage,
        notifications: notifications,
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

    test('notifies listeners when creating, completing, and deleting tasks',
        () async {
      int notifyCount = 0;
      controller.addListener(() {
        notifyCount++;
      });

      // 1. Create task
      final created = await controller.createTask(
        title: 'Complete tax report',
        notes: 'Gather all receipts',
      );

      expect(created.title, 'Complete tax report');
      expect(controller.visibleTasks.length, 1);
      expect(notifyCount, greaterThanOrEqualTo(1));

      // 2. Complete task
      await controller.completeTask(created.id);
      expect(controller.visibleTasks, isEmpty);

      // Check under completed filter
      controller.setFilter(TaskFilter.completed);
      expect(controller.visibleTasks.length, 1);
      expect(controller.visibleTasks.first.isCompleted, isTrue);

      // 3. Delete task
      await controller.deleteTask(created.id);
      expect(controller.visibleTasks, isEmpty);
    });

    test('filters tasks according to active filter and search text', () async {
      final t1 = await controller.createTask(
          title: 'Grocery shopping', notes: 'Milk and bread');
      final t2 = await controller.createTask(
          title: 'Write blog post', notes: 'Flutter architecture');

      expect(controller.visibleTasks.length, 2);

      controller.setSearchQuery('grocery');
      expect(controller.visibleTasks.length, 1);
      expect(controller.visibleTasks.first.id, t1.id);

      controller.setSearchQuery('flutter');
      expect(controller.visibleTasks.length, 1);
      expect(controller.visibleTasks.first.id, t2.id);

      controller.setSearchQuery('');
      expect(controller.visibleTasks.length, 2);
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

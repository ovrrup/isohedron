import 'package:test/test.dart';
import 'package:isohedron/models/task_item.dart';
import 'package:isohedron/services/notification_service.dart';

void main() {
  group('NotificationService', () {
    late NotificationService notificationService;
    late MockNotificationAdapter mockAdapter;

    setUp(() async {
      mockAdapter = MockNotificationAdapter();
      notificationService = NotificationService(adapter: mockAdapter);
      await notificationService.init();
    });

    test('generates consistent positive 32-bit integer IDs', () {
      final id1 = notificationService.computeNotificationId('task-abc-123');
      final id2 = notificationService.computeNotificationId('task-abc-123');
      final id3 = notificationService.computeNotificationId('task-xyz-999');

      expect(id1, equals(id2));
      expect(id1, isNonNegative);
      expect(id1, isNot(equals(id3)));
      expect(id1, lessThan(2147483647));
    });

    test('schedules reminder for future planned time', () async {
      final futureTime = DateTime.now().add(const Duration(hours: 2));
      final task = TaskItem(
        id: 'task-1',
        taskListId: 'local_default',
        title: 'Review quarterly goals',
        notes: 'Check revenue metrics',
        plannedTime: futureTime,
        updatedAt: DateTime.now(),
      );

      await notificationService.scheduleTaskReminder(task);

      expect(mockAdapter.scheduled.length, 1);
      final scheduled = mockAdapter.scheduled.first;
      expect(scheduled.title, 'Isohedron: Review quarterly goals');
      expect(scheduled.scheduledTime, futureTime);
      expect(scheduled.id, notificationService.computeNotificationId('task-1'));
    });

    test('Review Focus: handles past planned time safely with immediate trigger', () async {
      final pastTime = DateTime.now().subtract(const Duration(minutes: 15));
      final task = TaskItem(
        id: 'task-past',
        taskListId: 'local_default',
        title: 'Overdue task reminder',
        plannedTime: pastTime,
        updatedAt: DateTime.now(),
      );

      await notificationService.scheduleTaskReminder(task);

      // Should deliver immediate notification rather than scheduling in past
      expect(mockAdapter.immediate.length, 1);
      expect(mockAdapter.scheduled.isEmpty, isTrue);
      expect(mockAdapter.immediate.first.title, contains('Overdue task reminder'));
    });

    test('does not schedule reminder if task has no plannedTime', () async {
      final task = TaskItem(
        id: 'task-none',
        taskListId: 'local_default',
        title: 'Unplanned task',
        updatedAt: DateTime.now(),
      );

      await notificationService.scheduleTaskReminder(task);
      expect(mockAdapter.scheduled, isEmpty);
      expect(mockAdapter.immediate, isEmpty);
    });

    test('cancels scheduled reminder by task ID', () async {
      final task = TaskItem(
        id: 'task-to-cancel',
        taskListId: 'local_default',
        title: 'Task to cancel',
        plannedTime: DateTime.now().add(const Duration(hours: 1)),
        updatedAt: DateTime.now(),
      );

      await notificationService.scheduleTaskReminder(task);
      expect(mockAdapter.scheduled.length, 1);

      await notificationService.cancelReminder('task-to-cancel');
      expect(mockAdapter.scheduled, isEmpty);
    });
  });
}

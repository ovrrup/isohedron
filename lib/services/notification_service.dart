import '../models/task_item.dart';

class ScheduledNotificationRecord {
  final int id;
  final String title;
  final String body;
  final DateTime scheduledTime;

  const ScheduledNotificationRecord({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledTime,
  });
}

class ImmediateNotificationRecord {
  final int id;
  final String title;
  final String body;

  const ImmediateNotificationRecord({
    required this.id,
    required this.title,
    required this.body,
  });
}

abstract class NotificationAdapter {
  Future<void> init();
  Future<bool> requestPermissions();
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  });
  Future<void> showImmediate({
    required int id,
    required String title,
    required String body,
  });
  Future<void> cancel(int id);
  Future<void> cancelAll();
}

class MockNotificationAdapter implements NotificationAdapter {
  final List<ScheduledNotificationRecord> scheduled = [];
  final List<ImmediateNotificationRecord> immediate = [];

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    scheduled.removeWhere((item) => item.id == id);
    scheduled.add(ScheduledNotificationRecord(
      id: id,
      title: title,
      body: body,
      scheduledTime: scheduledTime,
    ));
  }

  @override
  Future<void> showImmediate({
    required int id,
    required String title,
    required String body,
  }) async {
    immediate.add(ImmediateNotificationRecord(
      id: id,
      title: title,
      body: body,
    ));
  }

  @override
  Future<void> cancel(int id) async {
    scheduled.removeWhere((item) => item.id == id);
  }

  @override
  Future<void> cancelAll() async {
    scheduled.clear();
    immediate.clear();
  }
}

class NotificationService {
  final NotificationAdapter _adapter;

  NotificationService({NotificationAdapter? adapter})
      : _adapter = adapter ?? MockNotificationAdapter();

  Future<void> init() async {
    await _adapter.init();
  }

  Future<bool> requestPermissions() async {
    return _adapter.requestPermissions();
  }

  int computeNotificationId(String taskId) {
    // 31-bit positive int hashing to stay well within Android/iOS 32-bit limits
    return taskId.hashCode.abs() % 2147483647;
  }

  Future<void> scheduleTaskReminder(TaskItem task) async {
    final planned = task.plannedTime;
    if (planned == null) return;

    final id = computeNotificationId(task.id);
    final title = 'Isohedron: ${task.title}';
    final body = task.notes ?? 'Time to tackle this planned task!';

    final now = DateTime.now();
    if (planned.isBefore(now)) {
      // Overdue or immediate trigger
      await _adapter.showImmediate(
        id: id,
        title: title,
        body: body,
      );
    } else {
      await _adapter.schedule(
        id: id,
        title: title,
        body: body,
        scheduledTime: planned,
      );
    }
  }

  Future<void> cancelReminder(String taskId) async {
    final id = computeNotificationId(taskId);
    await _adapter.cancel(id);
  }

  Future<void> cancelAll() async {
    await _adapter.cancelAll();
  }
}

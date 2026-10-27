import 'package:test/test.dart';
import 'package:isohedron/models/task_item.dart';
import 'package:isohedron/models/task_filter.dart';
import 'package:isohedron/models/task_list.dart';

void main() {
  group('TaskFilter & TaskList', () {
    test('TaskFilter has expected values', () {
      expect(TaskFilter.values.map((e) => e.name), [
        'all',
        'today',
        'planned',
        'completed',
        'cancelled',
      ]);
    });

    test('TaskList serialization works', () {
      const list = TaskList(
        id: 'list-1',
        title: 'Work Tasks',
        isDefault: true,
        isLocal: false,
      );

      final map = list.toMap();
      final revived = TaskList.fromMap(map);

      expect(revived.id, 'list-1');
      expect(revived.title, 'Work Tasks');
      expect(revived.isDefault, isTrue);
      expect(revived.isLocal, isFalse);
    });
  });

  group('TaskItem parsing & reflection in-note logic', () {
    test('parses plain notes without metadata', () {
      final task = TaskItem.parseFromGoogleTask(
        id: 'task-1',
        taskListId: 'list-1',
        title: 'Buy milk',
        rawNotes: '2% organic milk from grocery',
        due: DateTime(2026, 10, 27),
        isCompleted: false,
        updatedAt: DateTime(2026, 10, 27, 8, 0),
      );

      expect(task.title, 'Buy milk');
      expect(task.notes, '2% organic milk from grocery');
      expect(task.plannedTime, isNull);
      expect(task.isCancelled, isFalse);
      expect(task.cancelReason, isNull);
    });

    test('extracts [Planned: ...] timestamp and cleans user notes', () {
      const raw = 'Call dentist\n\n[Planned: 2026-10-27T15:30:00Z]';
      final task = TaskItem.parseFromGoogleTask(
        id: 'task-2',
        taskListId: 'list-1',
        title: 'Doctor Appointment',
        rawNotes: raw,
        isCompleted: false,
        updatedAt: DateTime.now(),
      );

      expect(task.notes, 'Call dentist');
      expect(task.plannedTime, isNotNull);
      expect(task.plannedTime!.toUtc().hour, 15);
      expect(task.plannedTime!.toUtc().minute, 30);
    });

    test('extracts [Cancelled: <reason> on <date>] and marks isCancelled', () {
      const raw =
          'Submit taxes\n---\n[Cancelled: Procrastinated and lacked documents on 2026-10-27]';
      final task = TaskItem.parseFromGoogleTask(
        id: 'task-3',
        taskListId: 'list-1',
        title: 'Tax Filing',
        rawNotes: raw,
        isCompleted: true, // Google Tasks maps cancelled to completed
        updatedAt: DateTime.now(),
      );

      expect(task.notes, 'Submit taxes');
      expect(task.isCancelled, isTrue);
      expect(task.cancelReason, 'Procrastinated and lacked documents');
    });

    test('Review Focus: gracefully handles corrupted or malformed tags', () {
      const malformed =
          'My note\n[Planned: not-a-date]\n[Cancelled: missing-on-clause]';
      final task = TaskItem.parseFromGoogleTask(
        id: 'task-4',
        taskListId: 'list-1',
        title: 'Malformed Test',
        rawNotes: malformed,
        isCompleted: false,
        updatedAt: DateTime.now(),
      );

      // Should not throw or crash; fall back cleanly
      expect(task.plannedTime, isNull);
      expect(task.isCancelled, isTrue); // extracted reason without date
      expect(task.cancelReason, 'missing-on-clause');
      expect(task.notes, 'My note');
    });

    test(
        'cancellation reason does not strip text containing word on without date',
        () {
      const note =
          'Bugfix task\n---\n[Cancelled: Stuck on backend database issue]';
      final task = TaskItem.parseFromGoogleTask(
        id: 'task-on-word',
        taskListId: 'list-1',
        title: 'Fix issue',
        rawNotes: note,
        isCompleted: true,
        updatedAt: DateTime.now(),
      );

      expect(task.isCancelled, isTrue);
      expect(task.cancelReason, 'Stuck on backend database issue');
    });

    test('TaskItem.copyWith supports clearing nullable fields', () {
      final task = TaskItem(
        id: 't-clear',
        taskListId: 'list-1',
        title: 'Test clear',
        plannedTime: DateTime(2026, 10, 27, 10, 0),
        cancelReason: 'Reason',
        isCancelled: true,
        updatedAt: DateTime.now(),
      );

      final cleared = task.copyWith(
        clearPlannedTime: true,
        clearCancelReason: true,
        isCancelled: false,
      );

      expect(cleared.plannedTime, isNull);
      expect(cleared.cancelReason, isNull);
      expect(cleared.isCancelled, isFalse);
    });

    test('serializes back to Google Notes accurately', () {
      final googleNotes = TaskItem.toGoogleNotes(
        userNotes: 'Original user note',
        plannedTime: DateTime.utc(2026, 10, 27, 18, 0),
        cancelReason: 'Rain delayed the outdoor plan',
      );

      expect(googleNotes, contains('Original user note'));
      expect(googleNotes, contains('[Planned: 2026-10-27T18:00:00.000Z]'));
      expect(
          googleNotes, contains('[Cancelled: Rain delayed the outdoor plan'));
    });

    test('JSON serialization toMap/fromMap preserves all state', () {
      final task = TaskItem(
        id: 'task-5',
        taskListId: 'list-1',
        title: 'Reflect on day',
        notes: 'Personal reflection',
        due: DateTime(2026, 10, 27),
        plannedTime: DateTime(2026, 10, 27, 21, 0),
        isCompleted: false,
        isCancelled: true,
        cancelReason: 'Fell asleep',
        updatedAt: DateTime(2026, 10, 27, 22, 0),
      );

      final map = task.toMap();
      final revived = TaskItem.fromMap(map);

      expect(revived.id, task.id);
      expect(revived.title, task.title);
      expect(revived.notes, task.notes);
      expect(revived.plannedTime, task.plannedTime);
      expect(revived.isCancelled, isTrue);
      expect(revived.cancelReason, 'Fell asleep');
    });
  });
}

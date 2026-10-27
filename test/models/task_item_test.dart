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
        isLocal: true,
      );

      final map = list.toMap();
      final revived = TaskList.fromMap(map);

      expect(revived.id, 'list-1');
      expect(revived.title, 'Work Tasks');
      expect(revived.isDefault, isTrue);
      expect(revived.isLocal, isTrue);
    });
  });

  group('TaskItem local model & serialization', () {
    test('creates TaskItem with default flags', () {
      final now = DateTime.now();
      final task = TaskItem(
        id: 'task-1',
        taskListId: 'list-1',
        title: 'Buy milk',
        notes: '2% organic milk from grocery',
        due: DateTime(2026, 10, 27),
        updatedAt: now,
      );

      expect(task.title, 'Buy milk');
      expect(task.notes, '2% organic milk from grocery');
      expect(task.plannedTime, isNull);
      expect(task.isCompleted, isFalse);
      expect(task.isCancelled, isFalse);
      expect(task.cancelReason, isNull);
    });

    test('TaskItem.copyWith supports updating and clearing nullable fields', () {
      final task = TaskItem(
        id: 't-clear',
        taskListId: 'list-1',
        title: 'Test clear',
        plannedTime: DateTime(2026, 10, 27, 10, 0),
        cancelReason: 'Rain delayed event',
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

    test('JSON serialization toMap/fromMap preserves all fields', () {
      final planned = DateTime(2026, 10, 27, 14, 30);
      final due = DateTime(2026, 10, 28);
      final updated = DateTime(2026, 10, 27, 10, 0);

      final task = TaskItem(
        id: 'task-json-1',
        taskListId: 'list-default',
        title: 'Complete architecture design',
        notes: 'Include diagram and benchmarks',
        due: due,
        plannedTime: planned,
        isCompleted: true,
        isCancelled: false,
        cancelReason: null,
        updatedAt: updated,
      );

      final map = task.toMap();
      final revived = TaskItem.fromMap(map);

      expect(revived.id, task.id);
      expect(revived.taskListId, task.taskListId);
      expect(revived.title, task.title);
      expect(revived.notes, task.notes);
      expect(revived.due, due);
      expect(revived.plannedTime, planned);
      expect(revived.isCompleted, isTrue);
      expect(revived.isCancelled, isFalse);
      expect(revived.updatedAt, updated);
    });
  });
}

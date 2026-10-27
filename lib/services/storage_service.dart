import 'dart:convert';
import 'dart:io';
import '../models/task_filter.dart';
import '../models/task_item.dart';
import '../models/task_list.dart';

class StorageService {
  final File? _storageFile;
  final Map<String, List<TaskItem>> _tasksByList = {};
  List<TaskList> _taskLists = [];
  String _selectedTaskListId = 'local_default';

  StorageService({File? storageFile}) : _storageFile = storageFile;

  factory StorageService.inMemory() => StorageService(storageFile: null);

  static const TaskList defaultLocalList = TaskList(
    id: 'local_default',
    title: 'My Tasks',
    isDefault: true,
    isLocal: true,
  );

  Future<void> init() async {
    final file = _storageFile;
    if (file != null && await file.exists()) {
      try {
        final content = await file.readAsString();
        if (content.trim().isNotEmpty) {
          final data = jsonDecode(content) as Map<String, dynamic>;
          _selectedTaskListId =
              (data['selectedTaskListId'] as String?) ?? 'local_default';

          final listsData = data['taskLists'] as List<dynamic>?;
          if (listsData != null && listsData.isNotEmpty) {
            _taskLists = listsData
                .map((e) => TaskList.fromMap(e as Map<String, dynamic>))
                .toList();
          } else {
            _taskLists = [defaultLocalList];
          }

          final tasksMapData = data['tasks'] as Map<String, dynamic>?;
          if (tasksMapData != null) {
            _tasksByList.clear();
            tasksMapData.forEach((key, value) {
              final list = (value as List<dynamic>)
                  .map((e) => TaskItem.fromMap(e as Map<String, dynamic>))
                  .toList();
              _tasksByList[key] = list;
            });
          }
          return;
        }
      } catch (_) {
        // Fall back to defaults on corrupt storage
      }
    }

    // Default initialization
    if (_taskLists.isEmpty) {
      _taskLists = [defaultLocalList];
    }
    _selectedTaskListId = _taskLists.first.id;
    await _persist();
  }

  Future<void> _persist() async {
    final file = _storageFile;
    if (file == null) return;
    try {
      final data = {
        'selectedTaskListId': _selectedTaskListId,
        'taskLists': _taskLists.map((l) => l.toMap()).toList(),
        'tasks': _tasksByList.map(
          (k, v) => MapEntry(k, v.map((t) => t.toMap()).toList()),
        ),
      };
      await file.writeAsString(jsonEncode(data));
    } catch (_) {
      // Ignore file persistence errors in read-only / test contexts
    }
  }

  Future<List<TaskList>> getTaskLists() async {
    return List.unmodifiable(_taskLists);
  }

  Future<void> saveTaskLists(List<TaskList> lists) async {
    _taskLists = List.from(lists);
    if (!_taskLists.any((l) => l.id == _selectedTaskListId)) {
      _selectedTaskListId =
          _taskLists.isNotEmpty ? _taskLists.first.id : 'local_default';
    }
    await _persist();
  }

  Future<String> getSelectedTaskListId() async {
    return _selectedTaskListId;
  }

  Future<void> setSelectedTaskListId(String id) async {
    _selectedTaskListId = id;
    await _persist();
  }

  Future<List<TaskItem>> getTasks(String taskListId) async {
    return List.unmodifiable(_tasksByList[taskListId] ?? []);
  }

  Future<void> saveTasks(String taskListId, List<TaskItem> tasks) async {
    _tasksByList[taskListId] = List.from(tasks);
    await _persist();
  }

  Future<void> upsertTask(TaskItem task) async {
    final list = _tasksByList.putIfAbsent(task.taskListId, () => []);
    final index = list.indexWhere((t) => t.id == task.id);
    if (index >= 0) {
      list[index] = task;
    } else {
      list.add(task);
    }
    await _persist();
  }

  Future<void> deleteTask(String taskListId, String taskId) async {
    final list = _tasksByList[taskListId];
    if (list != null) {
      list.removeWhere((t) => t.id == taskId);
      await _persist();
    }
  }

  List<TaskItem> filterTasks(
    List<TaskItem> tasks,
    TaskFilter filter, {
    String? searchQuery,
  }) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final filtered = tasks.where((task) {
      switch (filter) {
        case TaskFilter.all:
          // Active tasks that are neither completed nor cancelled
          return !task.isCompleted && !task.isCancelled;

        case TaskFilter.today:
          if (task.isCompleted || task.isCancelled) return false;
          final isDueToday = task.due != null &&
              task.due!.isAfter(startOfToday.subtract(const Duration(seconds: 1))) &&
              task.due!.isBefore(endOfToday.add(const Duration(seconds: 1)));
          final isPlannedToday = task.plannedTime != null &&
              task.plannedTime!.isAfter(startOfToday.subtract(const Duration(seconds: 1))) &&
              task.plannedTime!.isBefore(endOfToday.add(const Duration(seconds: 1)));
          return isDueToday || isPlannedToday;

        case TaskFilter.planned:
          if (task.isCompleted || task.isCancelled) return false;
          return task.plannedTime != null;

        case TaskFilter.completed:
          return task.isCompleted && !task.isCancelled;

        case TaskFilter.cancelled:
          return task.isCancelled;
      }
    }).where((task) {
      if (searchQuery == null || searchQuery.trim().isEmpty) return true;
      final q = searchQuery.toLowerCase().trim();
      final titleMatch = task.title.toLowerCase().contains(q);
      final notesMatch = task.notes?.toLowerCase().contains(q) ?? false;
      final reasonMatch = task.cancelReason?.toLowerCase().contains(q) ?? false;
      return titleMatch || notesMatch || reasonMatch;
    }).toList();

    // Sort order:
    // Planned tasks prioritized by planned time, then due date, then updated time
    filtered.sort((a, b) {
      if (a.plannedTime != null && b.plannedTime != null) {
        return a.plannedTime!.compareTo(b.plannedTime!);
      }
      if (a.plannedTime != null) return -1;
      if (b.plannedTime != null) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });

    return filtered;
  }
}

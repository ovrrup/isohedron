import 'dart:convert';
import 'dart:io';
import '../models/task_filter.dart';
import '../models/task_item.dart';
import '../models/task_list.dart';

class StorageService {
  final File? _storageFile;
  final Map<String, List<TaskItem>> _tasksByList = {};
  final Set<String> _deletedTaskIds = {};
  List<TaskList> _taskLists = [];
  String _selectedTaskListId = 'local_default';
  String? _googleAccessToken;
  String? _googleUserEmail;
  bool _hasCompletedOnboarding = false;

  StorageService({File? storageFile}) : _storageFile = storageFile;

  factory StorageService.inMemory() => StorageService(storageFile: null);

  bool get hasCompletedOnboarding => _hasCompletedOnboarding;

  Future<void> setHasCompletedOnboarding(bool value) async {
    _hasCompletedOnboarding = value;
    await _persist();
  }

  static const TaskList defaultLocalList = TaskList(
    id: 'local_default',
    title: 'My Tasks',
    isDefault: true,
    isLocal: true,
  );

  File? get _tmpFile {
    final file = _storageFile;
    return file != null ? File('${file.path}.tmp') : null;
  }

  File? get _bakFile {
    final file = _storageFile;
    return file != null ? File('${file.path}.bak') : null;
  }

  Future<void> init() async {
    final file = _storageFile;
    if (file != null) {
      bool loaded = false;

      // 1. Try reading primary storage file
      if (await file.exists()) {
        try {
          final content = await file.readAsString();
          if (_loadFromJson(content)) {
            loaded = true;
          }
        } catch (_) {
          // File corrupted or read error; attempt backup recovery
        }
      }

      // 2. Fall back to .bak if primary failed or corrupted
      if (!loaded && _bakFile != null && await _bakFile!.exists()) {
        try {
          final bakContent = await _bakFile!.readAsString();
          if (_loadFromJson(bakContent)) {
            loaded = true;
            // Restore primary from backup
            await _persist();
          }
        } catch (_) {
          // Both corrupted; will initialize defaults
        }
      }

      if (loaded) return;
    }

    // Default initialization
    if (_taskLists.isEmpty) {
      _taskLists = [defaultLocalList];
    }
    _selectedTaskListId = _taskLists.first.id;
    await _persist();
  }

  bool _loadFromJson(String content) {
    if (content.trim().isEmpty) return false;
    final data = jsonDecode(content) as Map<String, dynamic>;

    _selectedTaskListId =
        (data['selectedTaskListId'] as String?) ?? 'local_default';
    _googleAccessToken = data['googleAccessToken'] as String?;
    _googleUserEmail = data['googleUserEmail'] as String?;
    _hasCompletedOnboarding =
        (data['hasCompletedOnboarding'] as bool?) ?? false;

    final listsData = data['taskLists'] as List<dynamic>?;
    if (listsData != null && listsData.isNotEmpty) {
      _taskLists = listsData
          .map((e) => TaskList.fromMap(e as Map<String, dynamic>))
          .toList();
    } else {
      _taskLists = [defaultLocalList];
    }

    final tasksMapData = data['tasks'] as Map<String, dynamic>?;
    _tasksByList.clear();
    if (tasksMapData != null) {
      tasksMapData.forEach((key, value) {
        final list = (value as List<dynamic>)
            .map((e) => TaskItem.fromMap(e as Map<String, dynamic>))
            .toList();
        _tasksByList[key] = list;
      });
    }

    final deletedData = data['deletedTaskIds'] as List<dynamic>?;
    _deletedTaskIds.clear();
    if (deletedData != null) {
      _deletedTaskIds.addAll(deletedData.cast<String>());
    }

    return true;
  }

  Future<void> _persist() async {
    final file = _storageFile;
    if (file == null) return;

    try {
      final data = {
        'selectedTaskListId': _selectedTaskListId,
        'googleAccessToken': _googleAccessToken,
        'googleUserEmail': _googleUserEmail,
        'hasCompletedOnboarding': _hasCompletedOnboarding,
        'taskLists': _taskLists.map((l) => l.toMap()).toList(),
        'tasks': _tasksByList.map(
          (k, v) => MapEntry(k, v.map((t) => t.toMap()).toList()),
        ),
        'deletedTaskIds': _deletedTaskIds.toList(),
      };
      final jsonString = jsonEncode(data);

      // Atomic file write using .tmp and .bak
      final tmp = _tmpFile!;
      final bak = _bakFile!;

      await tmp.writeAsString(jsonString, flush: true);

      if (await file.exists()) {
        try {
          await file.copy(bak.path);
        } catch (_) {}
      }

      await tmp.rename(file.path);
    } catch (_) {
      // In read-only/test filesystems, ignore file persistence errors
    }
  }

  // --- Task Lists ---

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

  Future<TaskList> createTaskList(String title, {bool isLocal = true}) async {
    final list = TaskList(
      id: 'list_${DateTime.now().microsecondsSinceEpoch}',
      title: title.trim().isEmpty ? 'Untitled List' : title.trim(),
      isDefault: false,
      isLocal: isLocal,
    );
    _taskLists.add(list);
    await _persist();
    return list;
  }

  Future<void> deleteTaskList(String taskListId) async {
    _taskLists.removeWhere((l) => l.id == taskListId);
    _tasksByList.remove(taskListId);
    if (_selectedTaskListId == taskListId) {
      _selectedTaskListId =
          _taskLists.isNotEmpty ? _taskLists.first.id : 'local_default';
    }
    await _persist();
  }

  Future<String> getSelectedTaskListId() async => _selectedTaskListId;

  Future<void> setSelectedTaskListId(String id) async {
    _selectedTaskListId = id;
    await _persist();
  }

  // --- Tasks ---

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
    // If the task was previously tombstoned, untombstone it
    _deletedTaskIds.remove(task.id);
    await _persist();
  }

  Future<void> replaceTaskId(String oldId, TaskItem newTask) async {
    final list = _tasksByList[newTask.taskListId];
    if (list != null) {
      final index = list.indexWhere((t) => t.id == oldId);
      if (index >= 0) {
        list[index] = newTask;
      } else {
        list.add(newTask);
      }
    } else {
      _tasksByList[newTask.taskListId] = [newTask];
    }
    _deletedTaskIds.remove(oldId);
    await _persist();
  }

  Future<void> deleteTask(String taskListId, String taskId) async {
    final list = _tasksByList[taskListId];
    if (list != null) {
      list.removeWhere((t) => t.id == taskId);
    }
    // Only track tombstones for remote IDs or persistent keys to sync deletion
    if (!taskId.startsWith('local_task_')) {
      _deletedTaskIds.add(taskId);
    }
    await _persist();
  }

  // --- Deletion Tombstones ---

  Set<String> getDeletedTaskIds() => Set.unmodifiable(_deletedTaskIds);

  Future<void> purgeDeletedTaskId(String taskId) async {
    if (_deletedTaskIds.remove(taskId)) {
      await _persist();
    }
  }

  // --- Calendar & Timezone Date Helpers ---

  static bool isSameCalendarDay(DateTime date1, DateTime date2) {
    final d1 = date1.toLocal();
    final d2 = date2.toLocal();
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  static bool isDueOnDate(DateTime due, DateTime referenceDate) {
    final refLocal = referenceDate.toLocal();
    // Google Tasks date-only due dates arrive as UTC midnight (00:00:00.000Z)
    if (due.isUtc && due.hour == 0 && due.minute == 0 && due.second == 0) {
      return due.year == refLocal.year &&
          due.month == refLocal.month &&
          due.day == refLocal.day;
    }
    return isSameCalendarDay(due, referenceDate);
  }

  List<TaskItem> filterTasks(
    List<TaskItem> tasks,
    TaskFilter filter, {
    String? searchQuery,
  }) {
    final now = DateTime.now();

    final filtered = tasks.where((task) {
      switch (filter) {
        case TaskFilter.all:
          return !task.isCompleted && !task.isCancelled;

        case TaskFilter.today:
          if (task.isCompleted || task.isCancelled) return false;
          final isDueToday = task.due != null && isDueOnDate(task.due!, now);
          final isPlannedToday = task.plannedTime != null &&
              isSameCalendarDay(task.plannedTime!, now);
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

    // Prioritize planned tasks by time, then due date, then updated time
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

  // --- Auth Persistence ---

  Future<String?> getGoogleAccessToken() async => _googleAccessToken;
  Future<String?> getGoogleUserEmail() async => _googleUserEmail;

  Future<void> saveGoogleAuth({String? token, String? email}) async {
    _googleAccessToken = token;
    _googleUserEmail = email;
    await _persist();
  }

  Future<void> clearGoogleAuth() async {
    _googleAccessToken = null;
    _googleUserEmail = null;
    await _persist();
  }
}

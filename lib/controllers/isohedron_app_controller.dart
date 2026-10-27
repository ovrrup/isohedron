import 'package:flutter/foundation.dart';
import '../models/task_filter.dart';
import '../models/task_item.dart';
import '../models/task_list.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

class IsohedronAppController extends ChangeNotifier {
  final StorageService storage;
  final NotificationService notifications;

  TaskFilter _currentFilter = TaskFilter.all;
  String _searchQuery = '';
  List<TaskList> _taskLists = [];
  String _selectedListId = 'local_default';
  List<TaskItem> _currentTasks = [];
  bool _isInitialized = false;

  IsohedronAppController({
    required this.storage,
    required this.notifications,
  });

  TaskFilter get currentFilter => _currentFilter;
  String get searchQuery => _searchQuery;
  List<TaskList> get taskLists => List.unmodifiable(_taskLists);
  String get selectedListId => _selectedListId;
  bool get isInitialized => _isInitialized;
  bool get hasCompletedOnboarding => storage.hasCompletedOnboarding;

  Future<void> completeOnboarding() async {
    await storage.setHasCompletedOnboarding(true);
    notifyListeners();
  }

  Future<void> resetOnboarding() async {
    await storage.setHasCompletedOnboarding(false);
    notifyListeners();
  }

  TaskList get currentList {
    return _taskLists.firstWhere(
      (l) => l.id == _selectedListId,
      orElse: () => _taskLists.isNotEmpty
          ? _taskLists.first
          : StorageService.defaultLocalList,
    );
  }

  List<TaskItem> get allTasksForCurrentList => List.unmodifiable(_currentTasks);

  List<TaskItem> get visibleTasks {
    return storage.filterTasks(
      _currentTasks,
      _currentFilter,
      searchQuery: _searchQuery,
    );
  }

  List<TaskItem> get overdueTasks {
    final now = DateTime.now();
    return _currentTasks
        .where((t) =>
            !t.isCompleted &&
            !t.isCancelled &&
            t.plannedTime != null &&
            t.plannedTime!.isBefore(now))
        .toList();
  }

  Future<void> init() async {
    await storage.init();
    await notifications.init();

    await loadTaskLists();
    await loadCurrentTasks();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> loadTaskLists() async {
    _taskLists = await storage.getTaskLists();
    _selectedListId = await storage.getSelectedTaskListId();
    if (!_taskLists.any((l) => l.id == _selectedListId)) {
      _selectedListId = _taskLists.first.id;
      await storage.setSelectedTaskListId(_selectedListId);
    }
    notifyListeners();
  }

  Future<void> loadCurrentTasks() async {
    _currentTasks = await storage.getTasks(_selectedListId);
    notifyListeners();
  }

  void setFilter(TaskFilter filter) {
    if (_currentFilter != filter) {
      _currentFilter = filter;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
    }
  }

  Future<void> switchList(String listId) async {
    _selectedListId = listId;
    await storage.setSelectedTaskListId(listId);
    await loadCurrentTasks();
  }

  Future<TaskList> createTaskList(String title) async {
    final list = await storage.createTaskList(title);
    await loadTaskLists();
    await switchList(list.id);
    return list;
  }

  Future<void> deleteTaskList(String listId) async {
    if (listId == 'local_default') return; // Protect default list

    await storage.deleteTaskList(listId);
    await loadTaskLists();
    await loadCurrentTasks();
  }

  Future<TaskItem> createTask({
    required String title,
    String? notes,
    DateTime? due,
    DateTime? plannedTime,
  }) async {
    final task = TaskItem(
      id: 'task_${DateTime.now().microsecondsSinceEpoch}',
      taskListId: _selectedListId,
      title: title.trim(),
      notes: notes?.trim().isNotEmpty == true ? notes!.trim() : null,
      due: due,
      plannedTime: plannedTime,
      updatedAt: DateTime.now(),
    );

    await storage.upsertTask(task);
    if (plannedTime != null) {
      await notifications.scheduleTaskReminder(task);
    }

    await loadCurrentTasks();
    return task;
  }

  Future<void> completeTask(String taskId) async {
    final task = _currentTasks.cast<TaskItem?>().firstWhere(
          (t) => t?.id == taskId,
          orElse: () => null,
        );
    if (task == null) return;

    final updated = task.copyWith(
      isCompleted: true,
      isCancelled: false,
      clearCancelReason: true,
      updatedAt: DateTime.now(),
    );

    await storage.upsertTask(updated);
    await notifications.cancelReminder(taskId);

    await loadCurrentTasks();
  }

  Future<void> cancelTask(String taskId, {required String reason}) async {
    final task = _currentTasks.cast<TaskItem?>().firstWhere(
          (t) => t?.id == taskId,
          orElse: () => null,
        );
    if (task == null) return;

    final updated = task.copyWith(
      isCompleted: true,
      isCancelled: true,
      cancelReason: reason.trim(),
      updatedAt: DateTime.now(),
    );

    await storage.upsertTask(updated);
    await notifications.cancelReminder(taskId);

    await loadCurrentTasks();
  }

  Future<void> rescheduleTask(String taskId, DateTime newPlannedTime) async {
    final task = _currentTasks.cast<TaskItem?>().firstWhere(
          (t) => t?.id == taskId,
          orElse: () => null,
        );
    if (task == null) return;

    final updated = task.copyWith(
      plannedTime: newPlannedTime,
      isCompleted: false,
      isCancelled: false,
      clearCancelReason: true,
      updatedAt: DateTime.now(),
    );

    await storage.upsertTask(updated);
    await notifications.scheduleTaskReminder(updated);

    await loadCurrentTasks();
  }

  Future<void> clearReminder(String taskId) async {
    final task = _currentTasks.cast<TaskItem?>().firstWhere(
          (t) => t?.id == taskId,
          orElse: () => null,
        );
    if (task == null) return;

    final updated = task.copyWith(
      clearPlannedTime: true,
      updatedAt: DateTime.now(),
    );

    await storage.upsertTask(updated);
    await notifications.cancelReminder(taskId);

    await loadCurrentTasks();
  }

  Future<void> reopenTask(String taskId, {DateTime? newPlannedTime}) async {
    final task = _currentTasks.cast<TaskItem?>().firstWhere(
          (t) => t?.id == taskId,
          orElse: () => null,
        );
    if (task == null) return;

    final updated = task.copyWith(
      isCompleted: false,
      isCancelled: false,
      clearCancelReason: true,
      plannedTime: newPlannedTime ?? task.plannedTime,
      updatedAt: DateTime.now(),
    );

    await storage.upsertTask(updated);
    if (updated.plannedTime != null) {
      await notifications.scheduleTaskReminder(updated);
    }

    await loadCurrentTasks();
  }

  Future<void> deleteTask(String taskId) async {
    await storage.deleteTask(_selectedListId, taskId);
    await notifications.cancelReminder(taskId);
    await loadCurrentTasks();
  }
}

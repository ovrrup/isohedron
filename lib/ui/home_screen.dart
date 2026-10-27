import '../models/task_filter.dart';
import '../models/task_item.dart';
import '../models/task_list.dart';
import '../services/google_tasks_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

class IsohedronAppController {
  final StorageService storage;
  final NotificationService notifications;
  final GoogleTasksService googleTasks;

  TaskFilter _currentFilter = TaskFilter.all;
  String _searchQuery = '';
  List<TaskList> _taskLists = [];
  String _selectedListId = 'local_default';
  List<TaskItem> _currentTasks = [];
  bool _isSyncing = false;

  IsohedronAppController({
    required this.storage,
    required this.notifications,
    required this.googleTasks,
  });

  TaskFilter get currentFilter => _currentFilter;
  String get searchQuery => _searchQuery;
  List<TaskList> get taskLists => List.unmodifiable(_taskLists);
  String get selectedListId => _selectedListId;
  bool get isSyncing => _isSyncing;
  bool get isGoogleConnected => googleTasks.isAuthenticated;
  String? get googleEmail => googleTasks.userEmail;

  TaskList get currentList {
    return _taskLists.firstWhere(
      (l) => l.id == _selectedListId,
      orElse: () => _taskLists.isNotEmpty
          ? _taskLists.first
          : StorageService.defaultLocalList,
    );
  }

  List<TaskItem> get visibleTasks {
    return storage.filterTasks(
      _currentTasks,
      _currentFilter,
      searchQuery: _searchQuery,
    );
  }

  Future<void> init() async {
    await storage.init();
    await notifications.init();
    await loadTaskLists();
    await loadCurrentTasks();
  }

  Future<void> loadTaskLists() async {
    final localLists = await storage.getTaskLists();
    final combined = List<TaskList>.from(localLists);

    if (googleTasks.isAuthenticated) {
      try {
        final googleLists = await googleTasks.fetchTaskLists();
        for (final gList in googleLists) {
          if (!combined.any((l) => l.id == gList.id)) {
            combined.add(gList);
          }
        }
      } catch (_) {
        // Fall back to local lists on network failure
      }
    }

    _taskLists = combined;
    _selectedListId = await storage.getSelectedTaskListId();
    if (!_taskLists.any((l) => l.id == _selectedListId)) {
      _selectedListId = _taskLists.first.id;
      await storage.setSelectedTaskListId(_selectedListId);
    }
  }

  Future<void> loadCurrentTasks() async {
    _currentTasks = await storage.getTasks(_selectedListId);
  }

  void setFilter(TaskFilter filter) {
    _currentFilter = filter;
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
  }

  Future<void> switchList(String listId) async {
    _selectedListId = listId;
    await storage.setSelectedTaskListId(listId);
    await loadCurrentTasks();
  }

  Future<void> signInGoogle() async {
    final success = await googleTasks.signIn();
    if (success) {
      await loadTaskLists();
    }
  }

  Future<void> signOutGoogle() async {
    await googleTasks.signOut();
    await loadTaskLists();
    if (!currentList.isLocal) {
      await switchList('local_default');
    }
  }

  Future<void> syncCurrentList() async {
    if (!isGoogleConnected || currentList.isLocal) return;
    _isSyncing = true;
    try {
      await googleTasks.syncList(_selectedListId, storage);
      await loadCurrentTasks();
    } finally {
      _isSyncing = false;
    }
  }

  Future<TaskItem> createTask({
    required String title,
    String? notes,
    DateTime? due,
    DateTime? plannedTime,
  }) async {
    final task = TaskItem(
      id: 'task_${DateTime.now().millisecondsSinceEpoch}',
      taskListId: _selectedListId,
      title: title,
      notes: notes,
      due: due,
      plannedTime: plannedTime,
      updatedAt: DateTime.now(),
    );

    await storage.upsertTask(task);
    if (plannedTime != null) {
      await notifications.scheduleTaskReminder(task);
    }

    if (isGoogleConnected && !currentList.isLocal) {
      try {
        await googleTasks.pushTask(task);
      } catch (_) {
        // Queued locally in storage for next sync
      }
    }

    await loadCurrentTasks();
    return task;
  }

  Future<void> completeTask(String taskId) async {
    final task = _currentTasks.firstWhere((t) => t.id == taskId);
    final updated = task.copyWith(
      isCompleted: true,
      updatedAt: DateTime.now(),
    );

    await storage.upsertTask(updated);
    await notifications.cancelReminder(taskId);

    if (isGoogleConnected && !currentList.isLocal) {
      try {
        await googleTasks.pushTask(updated);
      } catch (_) {
        // Saved locally for sync
      }
    }

    await loadCurrentTasks();
  }

  Future<void> cancelTask(String taskId, {required String reason}) async {
    final task = _currentTasks.firstWhere((t) => t.id == taskId);
    final updated = task.copyWith(
      isCompleted: true, // Maps to completed so it clears active view
      isCancelled: true,
      cancelReason: reason,
      updatedAt: DateTime.now(),
    );

    await storage.upsertTask(updated);
    await notifications.cancelReminder(taskId);

    if (isGoogleConnected && !currentList.isLocal) {
      try {
        await googleTasks.pushTask(updated);
      } catch (_) {
        // Saved locally for sync
      }
    }

    await loadCurrentTasks();
  }

  Future<void> deleteTask(String taskId) async {
    await storage.deleteTask(_selectedListId, taskId);
    await notifications.cancelReminder(taskId);
    await loadCurrentTasks();
  }
}

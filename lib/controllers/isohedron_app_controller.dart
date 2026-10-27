import 'package:flutter/foundation.dart';
import '../models/task_filter.dart';
import '../models/task_item.dart';
import '../models/task_list.dart';
import '../services/google_tasks_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

class IsohedronAppController extends ChangeNotifier {
  final StorageService storage;
  final NotificationService notifications;
  final GoogleTasksService googleTasks;

  TaskFilter _currentFilter = TaskFilter.all;
  String _searchQuery = '';
  List<TaskList> _taskLists = [];
  String _selectedListId = 'local_default';
  List<TaskItem> _currentTasks = [];
  bool _isSyncing = false;
  bool _isInitialized = false;
  String? _errorMessage;

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
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  bool get hasCompletedOnboarding => storage.hasCompletedOnboarding;

  Future<void> completeOnboarding() async {
    await storage.setHasCompletedOnboarding(true);
    notifyListeners();
  }

  Future<void> resetOnboarding() async {
    await storage.setHasCompletedOnboarding(false);
    notifyListeners();
  }

  bool get isGoogleConnected => googleTasks.isAuthenticated;
  String? get googleEmail => googleTasks.userEmail;
  String? get googleLastError => googleTasks.lastError;

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

    // 1. Silent Google Play Services restoration
    try {
      await googleTasks.signInSilently();
    } catch (_) {}

    // 2. Persisted Direct OAuth Token restoration
    if (!googleTasks.isAuthenticated) {
      final savedToken = await storage.getGoogleAccessToken();
      final savedEmail = await storage.getGoogleUserEmail();
      if (savedToken != null && savedToken.trim().isNotEmpty) {
        try {
          await googleTasks.connectWithToken(savedToken, email: savedEmail);
        } catch (_) {}
      }
    }

    await loadTaskLists();
    await loadCurrentTasks();
    _isInitialized = true;
    notifyListeners();
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
        // Fall back to local lists on remote network error
      }
    }

    _taskLists = combined;
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
    if (isGoogleConnected && !listId.startsWith('local_')) {
      try {
        await googleTasks.deleteTaskList(listId);
      } catch (_) {}
    }
    await loadTaskLists();
    await loadCurrentTasks();
  }

  Future<bool> signInGoogle() async {
    final success = await googleTasks.signIn();
    if (success) {
      await loadTaskLists();
      await loadCurrentTasks();
      notifyListeners();
      return true;
    }
    notifyListeners();
    return false;
  }

  Future<bool> connectGoogleWithToken(String token, {String? email}) async {
    final success = await googleTasks.connectWithToken(token, email: email);
    if (success) {
      await storage.saveGoogleAuth(
        token: token.trim(),
        email: email?.trim().isNotEmpty == true
            ? email!.trim()
            : googleTasks.userEmail,
      );
      await loadTaskLists();
      await loadCurrentTasks();
      notifyListeners();
      return true;
    }
    notifyListeners();
    return false;
  }

  Future<void> signOutGoogle() async {
    await googleTasks.signOut();
    await storage.clearGoogleAuth();
    await loadTaskLists();
    if (!currentList.isLocal) {
      await switchList('local_default');
    }
    notifyListeners();
  }

  Future<void> syncCurrentList() async {
    if (!isGoogleConnected || currentList.isLocal || _isSyncing) return;
    _isSyncing = true;
    notifyListeners();

    try {
      await googleTasks.syncList(_selectedListId, storage);
      await loadCurrentTasks();
    } catch (e) {
      _errorMessage = 'Sync error: $e';
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<TaskItem> createTask({
    required String title,
    String? notes,
    DateTime? due,
    DateTime? plannedTime,
  }) async {
    final task = TaskItem(
      id: 'local_task_${DateTime.now().microsecondsSinceEpoch}',
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

    if (isGoogleConnected && !currentList.isLocal) {
      try {
        final pushed = await googleTasks.pushTask(task);
        // Atomically replace local ID with real Google Tasks remote ID
        await storage.replaceTaskId(task.id, pushed);
      } catch (_) {
        // Retained locally with local ID; syncList will reconcile later
      }
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

    if (isGoogleConnected && !currentList.isLocal) {
      try {
        await googleTasks.pushTask(updated);
      } catch (_) {}
    }

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

    if (isGoogleConnected && !currentList.isLocal) {
      try {
        await googleTasks.pushTask(updated);
      } catch (_) {}
    }

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

    if (isGoogleConnected && !currentList.isLocal) {
      try {
        await googleTasks.pushTask(updated);
      } catch (_) {}
    }

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

    if (isGoogleConnected && !currentList.isLocal) {
      try {
        await googleTasks.pushTask(updated);
      } catch (_) {}
    }

    await loadCurrentTasks();
  }

  Future<void> deleteTask(String taskId) async {
    await storage.deleteTask(_selectedListId, taskId);
    await notifications.cancelReminder(taskId);

    if (isGoogleConnected && !currentList.isLocal && !taskId.startsWith('local_')) {
      try {
        await googleTasks.deleteTask(_selectedListId, taskId);
        await storage.purgeDeletedTaskId(taskId);
      } catch (_) {
        // Tombstone remains in storage for next sync
      }
    }

    await loadCurrentTasks();
  }
}

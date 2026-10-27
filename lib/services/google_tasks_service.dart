import 'package:googleapis/tasks/v1.dart' as gtasks;
import 'package:http/http.dart' as http;
import '../models/task_item.dart';
import '../models/task_list.dart';
import 'storage_service.dart';

abstract class GoogleTasksClient {
  bool get isAuthenticated;
  String? get userEmail;
  Future<bool> signIn();
  Future<void> signOut();
  Future<List<TaskList>> fetchTaskLists();
  Future<List<TaskItem>> fetchTasks(String taskListId);
  Future<TaskItem> pushTask(TaskItem task);
}

class MockGoogleTasksClient implements GoogleTasksClient {
  final String _mockEmail;
  bool _signedIn = false;
  final List<TaskList> _lists;
  final Map<String, List<TaskItem>> _tasks;

  MockGoogleTasksClient({
    String mockEmail = 'user@example.com',
    List<TaskList>? initialLists,
    Map<String, List<TaskItem>>? initialTasks,
  })  : _mockEmail = mockEmail,
        _lists = List.from(initialLists ?? []),
        _tasks = initialTasks != null
            ? initialTasks.map((k, v) => MapEntry(k, List<TaskItem>.from(v)))
            : {};

  @override
  bool get isAuthenticated => _signedIn;

  @override
  String? get userEmail => _signedIn ? _mockEmail : null;

  @override
  Future<bool> signIn() async {
    _signedIn = true;
    return true;
  }

  @override
  Future<void> signOut() async {
    _signedIn = false;
  }

  @override
  Future<List<TaskList>> fetchTaskLists() async {
    if (!_signedIn) throw StateError('Not signed in to Google Tasks');
    return List.unmodifiable(_lists);
  }

  @override
  Future<List<TaskItem>> fetchTasks(String taskListId) async {
    if (!_signedIn) throw StateError('Not signed in to Google Tasks');
    return List.unmodifiable(_tasks[taskListId] ?? []);
  }

  @override
  Future<TaskItem> pushTask(TaskItem task) async {
    if (!_signedIn) throw StateError('Not signed in to Google Tasks');
    final list = _tasks.putIfAbsent(task.taskListId, () => []);

    // Format notes the same way Google Tasks API stores them
    final googleNotes = TaskItem.toGoogleNotes(
      userNotes: task.notes,
      plannedTime: task.plannedTime,
      cancelReason: task.cancelReason,
    );

    final updated = TaskItem.parseFromGoogleTask(
      id: task.id,
      taskListId: task.taskListId,
      title: task.title,
      rawNotes: googleNotes,
      due: task.due,
      isCompleted: task.isCompleted,
      updatedAt: DateTime.now(),
    );

    final idx = list.indexWhere((t) => t.id == task.id);
    if (idx >= 0) {
      list[idx] = updated;
    } else {
      list.add(updated);
    }
    return updated;
  }
}

class LiveGoogleTasksClient implements GoogleTasksClient {
  final http.Client _httpClient;
  gtasks.TasksApi? _tasksApi;
  String? _userEmail;

  LiveGoogleTasksClient({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  @override
  bool get isAuthenticated => _tasksApi != null;

  @override
  String? get userEmail => _userEmail;

  @override
  Future<bool> signIn() async {
    // In production mobile runtime, this receives the authenticated OAuth client.
    _tasksApi = gtasks.TasksApi(_httpClient);
    _userEmail = 'connected@google.com';
    return true;
  }

  @override
  Future<void> signOut() async {
    _tasksApi = null;
    _userEmail = null;
  }

  @override
  Future<List<TaskList>> fetchTaskLists() async {
    final api = _tasksApi;
    if (api == null) throw StateError('Not signed in to Google Tasks');

    final result = await api.tasklists.list();
    final items = result.items ?? [];
    return items.map((l) {
      return TaskList(
        id: l.id ?? '@default',
        title: l.title ?? 'My Tasks',
        isDefault: l.id == '@default',
        isLocal: false,
      );
    }).toList();
  }

  @override
  Future<List<TaskItem>> fetchTasks(String taskListId) async {
    final api = _tasksApi;
    if (api == null) throw StateError('Not signed in to Google Tasks');

    final result = await api.tasks.list(
      taskListId,
      showCompleted: true,
      showHidden: true,
    );
    final items = result.items ?? [];
    return items.map((t) {
      final isCompleted = t.status == 'completed';
      final updatedAt = t.updated != null ? DateTime.parse(t.updated!) : DateTime.now();
      final due = t.due != null ? DateTime.parse(t.due!) : null;

      return TaskItem.parseFromGoogleTask(
        id: t.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        taskListId: taskListId,
        title: t.title ?? 'Untitled Task',
        rawNotes: t.notes,
        due: due,
        isCompleted: isCompleted,
        updatedAt: updatedAt,
      );
    }).toList();
  }

  @override
  Future<TaskItem> pushTask(TaskItem task) async {
    final api = _tasksApi;
    if (api == null) throw StateError('Not signed in to Google Tasks');

    final googleNotes = TaskItem.toGoogleNotes(
      userNotes: task.notes,
      plannedTime: task.plannedTime,
      cancelReason: task.cancelReason,
    );

    final gTask = gtasks.Task(
      id: task.id.startsWith('local_') ? null : task.id,
      title: task.title,
      notes: googleNotes,
      status: (task.isCompleted || task.isCancelled) ? 'completed' : 'needsAction',
      due: task.due?.toUtc().toIso8601String(),
    );

    gtasks.Task response;
    if (gTask.id != null) {
      response = await api.tasks.update(gTask, task.taskListId, gTask.id!);
    } else {
      response = await api.tasks.insert(gTask, task.taskListId);
    }

    return TaskItem.parseFromGoogleTask(
      id: response.id ?? task.id,
      taskListId: task.taskListId,
      title: response.title ?? task.title,
      rawNotes: response.notes,
      due: response.due != null ? DateTime.parse(response.due!) : null,
      isCompleted: response.status == 'completed',
      updatedAt: response.updated != null ? DateTime.parse(response.updated!) : DateTime.now(),
    );
  }
}

class GoogleTasksService {
  final GoogleTasksClient _client;

  GoogleTasksService({GoogleTasksClient? client})
      : _client = client ?? LiveGoogleTasksClient();

  factory GoogleTasksService.mock({
    String mockEmail = 'user@example.com',
    List<TaskList>? initialLists,
    Map<String, List<TaskItem>>? initialTasks,
  }) {
    return GoogleTasksService(
      client: MockGoogleTasksClient(
        mockEmail: mockEmail,
        initialLists: initialLists,
        initialTasks: initialTasks,
      ),
    );
  }

  bool get isAuthenticated => _client.isAuthenticated;
  String? get userEmail => _client.userEmail;

  Future<bool> signIn() => _client.signIn();
  Future<void> signOut() => _client.signOut();

  Future<List<TaskList>> fetchTaskLists() => _client.fetchTaskLists();
  Future<List<TaskItem>> fetchTasks(String taskListId) =>
      _client.fetchTasks(taskListId);
  Future<TaskItem> pushTask(TaskItem task) => _client.pushTask(task);

  Future<void> syncList(String taskListId, StorageService storage) async {
    if (!isAuthenticated) return;

    final remoteTasks = await fetchTasks(taskListId);
    final localTasks = await storage.getTasks(taskListId);

    final merged = <String, TaskItem>{};

    for (final remote in remoteTasks) {
      merged[remote.id] = remote;
    }

    for (final local in localTasks) {
      if (!merged.containsKey(local.id)) {
        // Task created locally while offline -> push to Google Tasks
        final pushed = await pushTask(local);
        merged[pushed.id] = pushed;
      } else {
        final existing = merged[local.id]!;
        if (local.updatedAt.isAfter(existing.updatedAt)) {
          // Local update is newer -> push to remote
          final pushed = await pushTask(local);
          merged[pushed.id] = pushed;
        }
      }
    }

    await storage.saveTasks(taskListId, merged.values.toList());
  }
}

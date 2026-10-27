import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/tasks/v1.dart' as gtasks;
import 'package:http/http.dart' as http;
import '../models/task_item.dart';
import '../models/task_list.dart';
import 'storage_service.dart';

abstract class GoogleTasksClient {
  bool get isAuthenticated;
  String? get userEmail;
  String? get lastError;
  Future<bool> signIn();
  Future<bool> signInSilently();
  Future<bool> connectWithToken(String accessToken, {String? email});
  Future<void> signOut();
  Future<List<TaskList>> fetchTaskLists();
  Future<List<TaskItem>> fetchTasks(String taskListId);
  Future<TaskItem> pushTask(TaskItem task);
}

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client;

  GoogleAuthClient(this._headers, [http.Client? client])
      : _client = client ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
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
  String? get lastError => null;

  @override
  Future<bool> signIn() async {
    _signedIn = true;
    return true;
  }

  @override
  Future<bool> signInSilently() async {
    return _signedIn;
  }

  @override
  Future<bool> connectWithToken(String accessToken, {String? email}) async {
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
  final GoogleSignIn _googleSignIn;
  gtasks.TasksApi? _tasksApi;
  String? _userEmail;
  String? _lastError;

  LiveGoogleTasksClient({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: [
                'https://www.googleapis.com/auth/tasks',
              ],
            );

  @override
  bool get isAuthenticated => _tasksApi != null;

  @override
  String? get userEmail => _userEmail;

  @override
  String? get lastError => _lastError;

  @override
  Future<bool> signIn() async {
    _lastError = null;
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        _lastError = 'Sign in was cancelled.';
        return false;
      }
      final auth = await account.authHeaders;
      final authClient = GoogleAuthClient(auth);
      _tasksApi = gtasks.TasksApi(authClient);
      _userEmail = account.email;
      return true;
    } catch (e) {
      _lastError = e.toString();
      return false;
    }
  }

  @override
  Future<bool> signInSilently() async {
    _lastError = null;
    try {
      final account = await _googleSignIn.signInSilently();
      if (account == null) return false;
      final auth = await account.authHeaders;
      final authClient = GoogleAuthClient(auth);
      _tasksApi = gtasks.TasksApi(authClient);
      _userEmail = account.email;
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> connectWithToken(String accessToken, {String? email}) async {
    _lastError = null;
    final token = accessToken.trim();
    if (token.isEmpty) {
      _lastError = 'Access token cannot be empty.';
      return false;
    }

    try {
      final authClient = GoogleAuthClient({'Authorization': 'Bearer $token'});
      final api = gtasks.TasksApi(authClient);

      // Verify token validity by requesting tasklists
      await api.tasklists.list(maxResults: 1);

      _tasksApi = api;
      _userEmail = (email != null && email.trim().isNotEmpty)
          ? email.trim()
          : 'Google Tasks (OAuth Token)';
      return true;
    } catch (e) {
      _lastError = 'Failed to connect token: $e';
      return false;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
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

    final gTask = gtasks.Task()
      ..title = task.title
      ..notes = googleNotes
      ..status = task.isCompleted ? 'completed' : 'needsAction';

    if (task.due != null) {
      gTask.due = task.due!.toUtc().toIso8601String();
    }

    gtasks.Task resultTask;
    try {
      resultTask = await api.tasks.update(gTask, task.taskListId, task.id);
    } catch (_) {
      resultTask = await api.tasks.insert(gTask, task.taskListId);
    }

    final isCompleted = resultTask.status == 'completed';
    final updatedAt = resultTask.updated != null
        ? DateTime.parse(resultTask.updated!)
        : DateTime.now();

    return TaskItem.parseFromGoogleTask(
      id: resultTask.id ?? task.id,
      taskListId: task.taskListId,
      title: resultTask.title ?? task.title,
      rawNotes: resultTask.notes,
      due: task.due,
      isCompleted: isCompleted,
      updatedAt: updatedAt,
    );
  }
}

class GoogleTasksService {
  final GoogleTasksClient _client;

  GoogleTasksService({GoogleTasksClient? client})
      : _client = client ?? LiveGoogleTasksClient();

  factory GoogleTasksService.live([GoogleSignIn? googleSignIn]) =>
      GoogleTasksService(client: LiveGoogleTasksClient(googleSignIn: googleSignIn));

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
  String? get lastError => _client.lastError;

  Future<bool> signIn() => _client.signIn();
  Future<bool> signInSilently() => _client.signInSilently();
  Future<bool> connectWithToken(String accessToken, {String? email}) =>
      _client.connectWithToken(accessToken, email: email);
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

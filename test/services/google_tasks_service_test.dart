import 'package:test/test.dart';
import 'package:isohedron/models/task_item.dart';
import 'package:isohedron/models/task_list.dart';
import 'package:isohedron/services/google_tasks_service.dart';
import 'package:isohedron/services/storage_service.dart';

void main() {
  group('GoogleTasksService (Mock & Integration)', () {
    late GoogleTasksService googleService;
    late StorageService storage;

    setUp(() async {
      storage = StorageService.inMemory();
      await storage.init();

      googleService = GoogleTasksService.mock(
        mockEmail: 'testuser@gmail.com',
        initialLists: [
          const TaskList(
            id: 'g-list-default',
            title: 'Google My Tasks',
            isDefault: true,
            isLocal: false,
          ),
          const TaskList(
            id: 'g-list-work',
            title: 'Work Projects',
            isDefault: false,
            isLocal: false,
          ),
        ],
        initialTasks: {
          'g-list-default': [
            TaskItem(
              id: 'gt-1',
              taskListId: 'g-list-default',
              title: 'Remote task from Google Web',
              notes: 'Existing note',
              updatedAt: DateTime(2026, 10, 27, 9, 0),
            ),
          ],
        },
      );
    });

    test('initial auth state and sign in / sign out', () async {
      expect(googleService.isAuthenticated, isFalse);
      expect(googleService.userEmail, isNull);

      final success = await googleService.signIn();
      expect(success, isTrue);
      expect(googleService.isAuthenticated, isTrue);
      expect(googleService.userEmail, 'testuser@gmail.com');

      await googleService.signOut();
      expect(googleService.isAuthenticated, isFalse);
      expect(googleService.userEmail, isNull);
    });

    test('fetches remote task lists and remote tasks', () async {
      await googleService.signIn();

      final lists = await googleService.fetchTaskLists();
      expect(lists.length, 2);
      expect(lists.map((l) => l.title),
          containsAll(['Google My Tasks', 'Work Projects']));

      final tasks = await googleService.fetchTasks('g-list-default');
      expect(tasks.length, 1);
      expect(tasks.first.title, 'Remote task from Google Web');
    });

    test('pushes task with cancellation reason formatted into notes', () async {
      await googleService.signIn();

      final localCancelledTask = TaskItem(
        id: 'local-cancelled-1',
        taskListId: 'g-list-default',
        title: 'Cancel gym session',
        notes: 'Leg day',
        isCompleted: true,
        isCancelled: true,
        cancelReason: 'Sore muscles',
        updatedAt: DateTime.now(),
      );

      final pushed = await googleService.pushTask(localCancelledTask);
      expect(pushed.id, 'local-cancelled-1');

      // Verify remote reflection notes in mock backend
      final remoteTasks = await googleService.fetchTasks('g-list-default');
      final found = remoteTasks.firstWhere((t) => t.id == 'local-cancelled-1');
      expect(found.isCancelled, isTrue);
      expect(found.cancelReason, 'Sore muscles');
      expect(found.notes, 'Leg day');
    });

    test('syncList reconciles remote tasks into local storage', () async {
      await googleService.signIn();

      // Local storage starts empty for g-list-default
      expect(await storage.getTasks('g-list-default'), isEmpty);

      // Perform sync
      await googleService.syncList('g-list-default', storage);

      // Local storage now has the remote task
      final syncedLocal = await storage.getTasks('g-list-default');
      expect(syncedLocal.length, 1);
      expect(syncedLocal.first.title, 'Remote task from Google Web');

      // Add new local task and re-sync
      final localOnly = TaskItem(
        id: 'local-new',
        taskListId: 'g-list-default',
        title: 'Added offline locally',
        updatedAt: DateTime.now(),
      );
      await storage.upsertTask(localOnly);

      await googleService.syncList('g-list-default', storage);

      // Both tasks should exist remotely and locally
      final remoteTasks = await googleService.fetchTasks('g-list-default');
      expect(remoteTasks.map((t) => t.id), containsAll(['gt-1', 'local-new']));
    });

    test('connectWithToken and signInSilently support', () async {
      expect(googleService.isAuthenticated, isFalse);
      final connected = await googleService.connectWithToken('test-token',
          email: 'custom@domain.com');
      expect(connected, isTrue);
      expect(googleService.isAuthenticated, isTrue);

      final silent = await googleService.signInSilently();
      expect(silent, isTrue);

      await googleService.signOut();
      expect(googleService.isAuthenticated, isFalse);
    });

    test('syncList propagates local deletions and promotes local_task_ IDs',
        () async {
      await googleService.signIn();

      // 1. Add task with local_task_ prefix
      final offlineTask = TaskItem(
        id: 'local_task_offline_99',
        taskListId: 'g-list-default',
        title: 'Offline created idea',
        updatedAt: DateTime.now(),
      );
      await storage.upsertTask(offlineTask);

      // Perform sync
      await googleService.syncList('g-list-default', storage);

      // Verify the local ID was replaced with remote ID in local storage
      final localAfter = await storage.getTasks('g-list-default');
      expect(localAfter.any((t) => t.id == 'local_task_offline_99'), isFalse);
      expect(localAfter.any((t) => t.title == 'Offline created idea'), isTrue);

      // 2. Delete remote task locally and sync
      final remoteTaskToDelete =
          localAfter.firstWhere((t) => t.title == 'Offline created idea');
      await storage.deleteTask('g-list-default', remoteTaskToDelete.id);
      expect(storage.getDeletedTaskIds(), contains(remoteTaskToDelete.id));

      await googleService.syncList('g-list-default', storage);

      // Remote backend should now no longer have it, and tombstone is purged
      final remoteTasksAfter = await googleService.fetchTasks('g-list-default');
      expect(
          remoteTasksAfter.any((t) => t.id == remoteTaskToDelete.id), isFalse);
      expect(
          storage.getDeletedTaskIds(), isNot(contains(remoteTaskToDelete.id)));
    });

    test('LiveGoogleTasksClient exposes default GCP Client ID', () {
      expect(
        LiveGoogleTasksClient.defaultClientId,
        '123682783046-oitk011evt0thq64jvoluja61rl97nhv.apps.googleusercontent.com',
      );
    });
  });
}

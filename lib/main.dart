import 'dart:io';
import 'services/google_tasks_service.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'ui/home_screen.dart';

void main() async {
  // App initialization
  final storageFile = File('${Directory.current.path}/.isohedron_tasks.json');
  final storage = StorageService(storageFile: storageFile);
  final notifications = NotificationService();
  final googleTasks = GoogleTasksService.mock(
    mockEmail: 'demo@google.com',
  );

  final controller = IsohedronAppController(
    storage: storage,
    notifications: notifications,
    googleTasks: googleTasks,
  );

  await controller.init();
}

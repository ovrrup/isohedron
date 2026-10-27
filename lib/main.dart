import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'services/google_tasks_service.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';
import 'ui/home_screen.dart';
import 'ui/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  StorageService storage;
  try {
    final docsDir = await getApplicationDocumentsDirectory();
    final storageFile = File('${docsDir.path}/isohedron_tasks.json');
    storage = StorageService(storageFile: storageFile);
  } catch (e) {
    debugPrint('Storage directory fallback: $e');
    storage = StorageService.inMemory();
  }

  final notifications = NotificationService.local();
  final googleTasks = GoogleTasksService.live();

  final controller = IsohedronAppController(
    storage: storage,
    notifications: notifications,
    googleTasks: googleTasks,
  );

  try {
    await controller.init();
  } catch (e, stack) {
    debugPrint('Controller init non-fatal error: $e\n$stack');
  }

  runApp(IsohedronApp(controller: controller));
}

class IsohedronApp extends StatelessWidget {
  final IsohedronAppController controller;

  const IsohedronApp({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return MaterialApp(
          title: 'Isohedron',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          home: controller.hasCompletedOnboarding
              ? HomeScreen(controller: controller)
              : OnboardingScreen(controller: controller),
        );
      },
    );
  }
}

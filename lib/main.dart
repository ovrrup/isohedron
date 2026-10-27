import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'services/google_tasks_service.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'ui/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Storage persistence in app sandbox documents directory
  final docsDir = await getApplicationDocumentsDirectory();
  final storageFile = File('${docsDir.path}/isohedron_tasks.json');

  final storage = StorageService(storageFile: storageFile);
  final notifications = NotificationService.local();
  final googleTasks = GoogleTasksService.live();

  final controller = IsohedronAppController(
    storage: storage,
    notifications: notifications,
    googleTasks: googleTasks,
  );

  await controller.init();

  runApp(IsohedronApp(controller: controller));
}

class IsohedronApp extends StatelessWidget {
  final IsohedronAppController controller;

  const IsohedronApp({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF6366F1); // Indigo accent

    return MaterialApp(
      title: 'Isohedron Tasks',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
      ),
      themeMode: ThemeMode.system,
      home: HomeScreen(controller: controller),
    );
  }
}

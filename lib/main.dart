import 'dart:io';

import 'package:flutter/material.dart';
import 'services/hive_service.dart';
import 'services/workmanager_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await HiveService.initialize();

  // Initialize WorkManager
  await WorkManagerService.initialize();

  // Register periodic upload task
  await WorkManagerService.registerPeriodicTask();

  // iOS 13+ only
  if (Platform.isIOS) {
    await WorkManagerService.printScheduledTasks();
  }

  // Execute one off task whenever app is launched
  // This will upload all pending images immediately and in the background
  // Why work manager for this? Because it will work even if app is closed immediately after launching
  await WorkManagerService.registerOneOffTask();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Offline Upload Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

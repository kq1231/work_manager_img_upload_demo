import 'package:flutter/material.dart';
import 'services/hive_service.dart';
import 'services/workmanager_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await HiveService.initialize();
  print('✅ Hive initialized');
  
  // Initialize WorkManager
  await WorkManagerService.initialize();
  
  // Register periodic upload task
  await WorkManagerService.registerPeriodicTask();
  
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

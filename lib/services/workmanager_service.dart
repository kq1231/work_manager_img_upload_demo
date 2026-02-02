import 'package:workmanager/workmanager.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/pending_upload.dart';
import 'upload_service.dart';

// Background task callback - runs in separate isolate
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print('\n🔔 [BACKGROUND TASK] Started: $task');
    
    try {
      // Initialize Hive in this isolate
      await Hive.initFlutter();
      
      // Register adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(UploadStatusAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(PendingUploadAdapter());
      }
      
      // Open boxes
      await Hive.openBox<PendingUpload>('pending_uploads');
      await Hive.openBox('settings');
      
      // Process uploads
      final uploadService = UploadService();
      final results = await uploadService.processQueue();
      
      print('🔔 [BACKGROUND TASK] Completed: ${results['success']}/${results['total']} uploads succeeded');
      
      // Close Hive
      await Hive.close();
      
      return Future.value(true);
    } catch (e) {
      print('❌ [BACKGROUND TASK] Error: $e');
      return Future.value(false);
    }
  });
}

class WorkManagerService {
  static const String _uploadTaskName = 'uploadPendingImages';

  // Initialize WorkManager
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true, // Set to false in production
    );
    print('✅ WorkManager initialized');
  }

  // Register periodic upload task (runs every 15 minutes)
  static Future<void> registerPeriodicTask() async {
    await Workmanager().registerPeriodicTask(
      'periodicUploadTask',
      _uploadTaskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep, // Don't duplicate
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(seconds: 30),
    );
    print('✅ Periodic upload task registered (15 min interval)');
  }

  // Register one-off task (for immediate retry)
  static Future<void> registerOneOffTask() async {
    await Workmanager().registerOneOffTask(
      'oneOffUploadTask',
      _uploadTaskName,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(seconds: 30),
    );
    print('✅ One-off upload task registered');
  }

  // Cancel all tasks
  static Future<void> cancelAllTasks() async {
    await Workmanager().cancelAll();
    print('🛑 All WorkManager tasks cancelled');
  }

  // Cancel periodic task only
  static Future<void> cancelPeriodicTask() async {
    await Workmanager().cancelByUniqueName('periodicUploadTask');
    print('🛑 Periodic task cancelled');
  }
}

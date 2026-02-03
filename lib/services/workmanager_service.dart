import 'package:workmanager/workmanager.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/pending_upload.dart';
import 'upload_service.dart';

// Background task callback - runs in separate isolate
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final startTime = DateTime.now();
    print('\n' + '=' * 60);
    print('🔔 [BACKGROUND TASK] Started');
    print('=' * 60);
    print('📋 Task: $task');
    print('📊 Input data: $inputData');
    print('⏰ Start time: ${startTime.toIso8601String()}');
    print('🔢 Isolate: ${DateTime.now().millisecondsSinceEpoch}');
    
    try {
      // Initialize Hive in this isolate
      print('📦 Initializing Hive...');
      await Hive.initFlutter();
      
      // Register adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(UploadStatusAdapter());
        print('✅ UploadStatusAdapter registered');
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(PendingUploadAdapter());
        print('✅ PendingUploadAdapter registered');
      }
      
      // Open boxes
      print('📂 Opening Hive boxes...');
      await Hive.openBox<PendingUpload>('pending_uploads');
      await Hive.openBox('settings');
      print('✅ Hive boxes opened');
      
      // Process uploads
      print('🚀 Starting upload process...');
      final uploadService = UploadService();
      // Pass isBackgroundTask: true so retry count is incremented
      final results = await uploadService.processQueue(isBackgroundTask: true);
      
      final duration = DateTime.now().difference(startTime);
      print('\n' + '=' * 60);
      print('✅ [BACKGROUND TASK] COMPLETED');
      print('=' * 60);
      print('📊 Results: ${results['success']}/${results['total']} succeeded, ${results['failed']} failed');
      print('⏱️  Duration: ${duration.inSeconds}s');
      print('⏰ End time: ${DateTime.now().toIso8601String()}');
      print('=' * 60 + '\n');
      
      // Close Hive
      await Hive.close();
      
      return Future.value(true);
    } catch (e, stackTrace) {
      final duration = DateTime.now().difference(startTime);
      print('\n' + '=' * 60);
      print('❌ [BACKGROUND TASK] FAILED');
      print('=' * 60);
      print('💥 Error: $e');
      print('📋 Stack trace: $stackTrace');
      print('⏱️  Duration: ${duration.inSeconds}s');
      print('=' * 60 + '\n');
      return Future.value(false); // Retry
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
    print('📱 Platform: Android - Background tasks subject to battery optimization');
  }
  
  // Register one-off task for immediate execution (helpful for testing)
  static Future<void> registerOneOffTask() async {
    await Workmanager().registerOneOffTask(
      'oneOffUploadTask_${DateTime.now().millisecondsSinceEpoch}',
      _uploadTaskName,
      initialDelay: const Duration(seconds: 5),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
    print('✅ One-off task registered (will run in 5 seconds)');
  }

  // Register periodic upload task (runs every 15 minutes)
  static Future<void> registerPeriodicTask() async {
    // Cancel any existing task first to ensure clean registration
    await Workmanager().cancelByUniqueName('periodicUploadTask');
    
    await Workmanager().registerPeriodicTask(
      'periodicUploadTask',
      _uploadTaskName,
      frequency: const Duration(minutes: 15),
      // constraints: Constraints(
      //   networkType: NetworkType.connected,
      //   requiresBatteryNotLow: false, // Allow even when battery is low
      //   requiresCharging: false, // Allow even when not charging
      //   requiresDeviceIdle: false, // Don't wait for device idle
      //   requiresStorageNotLow: false, // Don't check storage
      // ),
      // existingWorkPolicy: ExistingPeriodicWorkPolicy.update, // Update if exists
      // backoffPolicy: BackoffPolicy.exponential,
      // backoffPolicyDelay: const Duration(seconds: 30),
    );
    print('✅ Periodic upload task registered (15 min interval)');
    print('⚠️  Note: First run in 10 seconds, then every 15 minutes');
    print('⚠️  Android may delay execution due to battery optimization');
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

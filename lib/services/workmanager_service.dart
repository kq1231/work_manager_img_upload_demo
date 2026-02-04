import 'package:workmanager/workmanager.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/pending_upload.dart';
import 'upload_service.dart';

// Background task callback - runs in separate isolate
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final startTime = DateTime.now();

    try {
      // iOS has a 30-second limit for background tasks
      // Add timeout to ensure we complete within limits
      final result = await Future.any([
        _executeUploadTask(),
        Future.delayed(Duration(seconds: 25), () {
          return {'timeout': true};
        }),
      ]);

      final duration = DateTime.now().difference(startTime);

      if (result['timeout'] == true) {
        return Future.value(
          true,
        ); // Still return true so task doesn't retry immediately
      }

      return Future.value(true);
    } catch (e, stackTrace) {
      final duration = DateTime.now().difference(startTime);
      return Future.value(true); // Don't let work manager retry on Android
    }
  });
}

// Helper function to execute the actual upload task
Future<Map<String, dynamic>> _executeUploadTask() async {
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
    // Pass isBackgroundTask: true so retry count is incremented
    final results = await uploadService.processQueue(isBackgroundTask: true);

    // Close Hive
    await Hive.close();

    return results;
  } catch (e) {
    rethrow;
  }
}

class WorkManagerService {
  static const String _uploadTaskName =
      'com.example.workManagerImgUploadDemo.uploadPendingImages';

  // Initialize WorkManager
  static Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher);
  }

  // Register one-off task for immediate execution (helpful for testing)
  static Future<void> registerOneOffTask() async {
    await Workmanager().registerOneOffTask(
      'oneOffUploadTask_${DateTime.now().millisecondsSinceEpoch}',
      _uploadTaskName,
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }

  // Register periodic upload task (runs every 15 minutes)
  static Future<void> registerPeriodicTask() async {
    await Workmanager().registerPeriodicTask(
      _uploadTaskName, // uniqueName for cancellation
      _uploadTaskName, // taskName that matches iOS identifier
      frequency: const Duration(minutes: 15), // 15 minutes interval
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: false, // Allow even when battery is low
        requiresCharging: false, // Allow even when not charging
        requiresDeviceIdle: false, // Don't wait for device idle
        requiresStorageNotLow: false, // Don't check storage
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update, // Update if exists
    );
  }

  // Cancel all tasks
  static Future<void> cancelAllTasks() async {
    await Workmanager().cancelAll();
  }

  // Cancel periodic task only
  static Future<void> cancelPeriodicTask() async {
    await Workmanager().cancelByUniqueName(_uploadTaskName);
  }

  // Print scheduled tasks
  static Future<String> printScheduledTasks() async {
    return await Workmanager().printScheduledTasks();
  }
}

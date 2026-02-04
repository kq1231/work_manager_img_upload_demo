import 'package:hive_flutter/hive_flutter.dart';
import '../models/pending_upload.dart';

class HiveService {
  static const String _uploadsBoxName = 'pending_uploads';
  static const String _settingsBoxName = 'settings';

  static Future<void> initialize() async {
    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UploadStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(PendingUploadAdapter());
    }

    // Open boxes
    await Hive.openBox<PendingUpload>(_uploadsBoxName);
    await Hive.openBox(_settingsBoxName);
  }

  // Upload Queue Operations
  static Box<PendingUpload> get uploadsBox =>
      Hive.box<PendingUpload>(_uploadsBoxName);

  static Future<void> addUpload(PendingUpload upload) async {
    await uploadsBox.put(upload.id, upload);
  }

  static List<PendingUpload> getPendingUploads() {
    // Return both pending and failed uploads (both need to be uploaded)
    return uploadsBox.values
        .where((upload) => upload.status == UploadStatus.pending)
        .toList();
  }

  static List<PendingUpload> getAllUploads() {
    return uploadsBox.values.toList();
  }

  static Future<void> updateUpload(PendingUpload upload) async {
    await upload.save();
  }

  static Future<void> removeUpload(String id) async {
    await uploadsBox.delete(id);
  }

  static Future<void> clearAllUploads() async {
    await uploadsBox.clear();
  }

  // Settings Operations
  static Box get settingsBox => Hive.box(_settingsBoxName);

  static String getApiUrl() {
    return settingsBox.get(
      'api_url',
      defaultValue: 'http://192.168.1.100:5001',
    );
  }

  static Future<void> setApiUrl(String url) async {
    await settingsBox.put('api_url', url);
  }

  static Future<void> close() async {
    await Hive.close();
  }
}

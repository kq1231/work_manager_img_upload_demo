import 'dart:io';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/pending_upload.dart';
import 'hive_service.dart';

class UploadService {
  final Dio _dio = Dio();
  final Connectivity _connectivity = Connectivity();

  // Check if device has internet connection
  Future<bool> hasConnection() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult.first != ConnectivityResult.none;
  }

  // Upload a single image
  // isBackgroundTask: true when called from WorkManager, false when called from UI
  Future<bool> uploadImage(
    PendingUpload upload, {
    bool isBackgroundTask = false,
  }) async {
    try {
      final apiUrl = HiveService.getApiUrl();

      // Mark last attempt time (no need for "uploading" state)
      upload.lastAttempt = DateTime.now();
      await HiveService.updateUpload(upload);

      // Create multipart request using image bytes from Hive
      final formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(
          upload.imageBytes,
          filename: upload.fileName,
        ),
        'patientId': upload.patientId,
        'woundId': upload.woundId,
        'metadata': '{"retryCount": ${upload.retryCount}}',
      });

      // Send request
      // iOS background tasks have 30s limit, use shorter timeout when in background
      final timeout = (Platform.isIOS && isBackgroundTask)
          ? const Duration(seconds: 10) // iOS background: 10s per image
          : const Duration(seconds: 30); // Foreground or Android: 30s

      final response = await _dio.post(
        '$apiUrl/api/upload',
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
          sendTimeout: timeout,
          receiveTimeout: timeout,
        ),
      );

      if (response.statusCode == 200) {
        // Remove from Hive (no file to delete since image is stored as bytes)
        await HiveService.removeUpload(upload.id);

        return true;
      } else {
        upload.errorMessage = 'Server returned ${response.statusCode}';

        // Only increment retry count if this is a background task
        if (isBackgroundTask) {
          upload.retryCount++;

          // Only mark as failed if max retries reached
          if (upload.retryCount >= 5) {
            upload.status = UploadStatus.failed;
          }
        } else {}
        // Otherwise stays as pending for automatic retry

        await HiveService.updateUpload(upload);
        return false;
      }
    } on DioException catch (e) {
      upload.errorMessage = e.message ?? 'Network error';

      // Only increment retry count if this is a background task
      if (isBackgroundTask) {
        upload.retryCount++;

        // Only mark as failed if max retries reached
        if (upload.retryCount >= 5) {
          upload.status = UploadStatus.failed;
        }
      } else {}
      // Otherwise stays as pending for automatic retry

      await HiveService.updateUpload(upload);
      return false;
    } catch (e) {
      upload.errorMessage = e.toString();

      // Only increment retry count if this is a background task
      if (isBackgroundTask) {
        upload.retryCount++;

        // Only mark as failed if max retries reached
        if (upload.retryCount >= 5) {
          upload.status = UploadStatus.failed;
        }
      } else {}
      // Otherwise stays as pending for automatic retry

      await HiveService.updateUpload(upload);
      return false;
    }
  }

  // Process all pending uploads
  // isBackgroundTask: true when called from WorkManager, false when called from UI
  Future<Map<String, int>> processQueue({bool isBackgroundTask = false}) async {
    if (!await hasConnection()) {
      return {'total': 0, 'success': 0, 'failed': 0};
    }

    final pending = HiveService.getPendingUploads();

    // Filter out already failed uploads
    final uploadsToProcess = pending;

    if (uploadsToProcess.isEmpty) {
      return {'total': 0, 'success': 0, 'failed': 0};
    }

    // iOS background tasks have 30-second limit
    // Limit parallel uploads on iOS background tasks to complete within time
    final isIOS = Platform.isIOS;
    if (isIOS && isBackgroundTask && uploadsToProcess.length > 3) {
      uploadsToProcess.removeRange(3, uploadsToProcess.length);
    }

    // Upload all images in parallel using Future.wait
    final results = await Future.wait(
      uploadsToProcess.map(
        (upload) => uploadImage(upload, isBackgroundTask: isBackgroundTask),
      ),
    );

    // Count successes and failures
    final successCount = results.where((success) => success).length;
    final failedCount = results.where((success) => !success).length;

    return {
      'total': uploadsToProcess.length,
      'success': successCount,
      'failed': failedCount,
    };
  }

  // Retry a specific upload (user-initiated, foreground)
  Future<bool> retryUpload(String uploadId) async {
    final upload = HiveService.uploadsBox.get(uploadId);
    if (upload == null) {
      return false;
    }

    // Reset status to pending
    upload.status = UploadStatus.pending;
    upload.errorMessage = null;
    await HiveService.updateUpload(upload);

    // This is a foreground user action, don't increment retry count
    return await uploadImage(upload, isBackgroundTask: false);
  }

  // Retry all failed uploads (user-initiated, foreground)
  Future<Map<String, int>> retryAllFailed() async {
    final failed = HiveService.getAllUploads()
        .where((u) => u.status == UploadStatus.failed)
        .toList();

    if (failed.isEmpty) {
      return {'total': 0, 'success': 0, 'failed': 0};
    }

    // Reset all to pending
    for (final upload in failed) {
      upload.status = UploadStatus.pending;
      upload.errorMessage = null;
      await HiveService.updateUpload(upload);
    }

    // This is a foreground user action, don't increment retry count
    // Process queue will handle parallel uploads
    return await processQueue(isBackgroundTask: false);
  }
}

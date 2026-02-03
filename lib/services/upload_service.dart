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
  Future<bool> uploadImage(PendingUpload upload, {bool isBackgroundTask = false}) async {
    try {
      final apiUrl = HiveService.getApiUrl();
      final file = File(upload.imagePath);
      
      if (!await file.exists()) {
        print('❌ Image file not found: ${upload.imagePath}');
        upload.status = UploadStatus.failed;
        upload.errorMessage = 'Image file not found';
        await HiveService.updateUpload(upload);
        return false;
      }

      // Mark last attempt time (no need for "uploading" state)
      upload.lastAttempt = DateTime.now();
      await HiveService.updateUpload(upload);

      // Create multipart request
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          upload.imagePath,
          filename: upload.imagePath.split('/').last,
        ),
        'patientId': upload.patientId,
        'woundId': upload.woundId,
        'metadata': '{"retryCount": ${upload.retryCount}}',
      });

      // Send request
      // iOS background tasks have 30s limit, use shorter timeout when in background
      final timeout = (Platform.isIOS && isBackgroundTask) 
          ? const Duration(seconds: 10)  // iOS background: 10s per image
          : const Duration(seconds: 30);  // Foreground or Android: 30s
      
      print('📤 Uploading ${upload.id} to $apiUrl/api/upload (timeout: ${timeout.inSeconds}s)');
      final response = await _dio.post(
        '$apiUrl/api/upload',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
          sendTimeout: timeout,
          receiveTimeout: timeout,
        ),
      );

      if (response.statusCode == 200) {
        print('✅ Upload successful: ${upload.id}');
        
        // Delete the image file
        await file.delete();
        print('🗑️  Deleted local image: ${upload.imagePath}');
        
        // Remove from Hive
        await HiveService.removeUpload(upload.id);
        
        return true;
      } else {
        print('❌ Upload failed with status ${response.statusCode}');
        upload.errorMessage = 'Server returned ${response.statusCode}';
        
        // Only increment retry count if this is a background task
        if (isBackgroundTask) {
          upload.retryCount++;
          print('📊 Retry count incremented to ${upload.retryCount} (background task)');
          
          // Only mark as failed if max retries reached
          if (upload.retryCount >= 5) {
            upload.status = UploadStatus.failed;
            print('⚠️  Max retries reached for ${upload.id}');
          }
        } else {
          print('ℹ️  Foreground attempt failed, retry count unchanged: ${upload.retryCount}');
        }
        // Otherwise stays as pending for automatic retry
        
        await HiveService.updateUpload(upload);
        return false;
      }
    } on DioException catch (e) {
      print('❌ Upload failed (DioException): ${e.message}');
      upload.errorMessage = e.message ?? 'Network error';
      
      // Only increment retry count if this is a background task
      if (isBackgroundTask) {
        upload.retryCount++;
        print('📊 Retry count incremented to ${upload.retryCount} (background task)');
        
        // Only mark as failed if max retries reached
        if (upload.retryCount >= 5) {
          upload.status = UploadStatus.failed;
          print('⚠️  Max retries reached for ${upload.id}');
        }
      } else {
        print('ℹ️  Foreground attempt failed, retry count unchanged: ${upload.retryCount}');
      }
      // Otherwise stays as pending for automatic retry
      
      await HiveService.updateUpload(upload);
      return false;
    } catch (e) {
      print('❌ Upload failed (Exception): $e');
      upload.errorMessage = e.toString();
      
      // Only increment retry count if this is a background task
      if (isBackgroundTask) {
        upload.retryCount++;
        print('📊 Retry count incremented to ${upload.retryCount} (background task)');
        
        // Only mark as failed if max retries reached
        if (upload.retryCount >= 5) {
          upload.status = UploadStatus.failed;
          print('⚠️  Max retries reached for ${upload.id}');
        }
      } else {
        print('ℹ️  Foreground attempt failed, retry count unchanged: ${upload.retryCount}');
      }
      // Otherwise stays as pending for automatic retry
      
      await HiveService.updateUpload(upload);
      return false;
    }
  }

  // Process all pending uploads
  // isBackgroundTask: true when called from WorkManager, false when called from UI
  Future<Map<String, int>> processQueue({bool isBackgroundTask = false}) async {
    print('🔄 Processing upload queue... (${isBackgroundTask ? 'BACKGROUND' : 'FOREGROUND'})');
    
    if (!await hasConnection()) {
      print('📡 No internet connection');
      return {'total': 0, 'success': 0, 'failed': 0};
    }

    final pending = HiveService.getPendingUploads();
    print('📋 Found ${pending.length} pending uploads');

    // Filter out already failed uploads
    final uploadsToProcess = pending.where((upload) {
      if (upload.status == UploadStatus.failed) {
        print('⏭️  Skipping ${upload.id} (marked as failed - needs manual retry)');
        return false;
      }
      return true;
    }).toList();

    if (uploadsToProcess.isEmpty) {
      print('ℹ️  No uploads to process');
      return {'total': 0, 'success': 0, 'failed': 0};
    }

    // iOS background tasks have 30-second limit
    // Limit parallel uploads on iOS background tasks to complete within time
    final isIOS = Platform.isIOS;
    if (isIOS && isBackgroundTask && uploadsToProcess.length > 3) {
      print('⚠️  iOS background mode: limiting to first 3 images (30s timeout)');
      print('ℹ️  Remaining ${uploadsToProcess.length - 3} will be processed in next run');
      uploadsToProcess.removeRange(3, uploadsToProcess.length);
    }

    print('⚡ Uploading ${uploadsToProcess.length} images in parallel...');
    
    // Upload all images in parallel using Future.wait
    final results = await Future.wait(
      uploadsToProcess.map((upload) => uploadImage(upload, isBackgroundTask: isBackgroundTask)),
    );

    // Count successes and failures
    final successCount = results.where((success) => success).length;
    final failedCount = results.where((success) => !success).length;

    print('✨ Queue processing complete: $successCount succeeded, $failedCount failed');
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
      print('❌ Upload not found: $uploadId');
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
    
    print('🔄 Retrying ${failed.length} failed uploads (user-initiated)');
    
    if (failed.isEmpty) {
      print('ℹ️  No failed uploads to retry');
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

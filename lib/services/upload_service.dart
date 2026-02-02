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
  Future<bool> uploadImage(PendingUpload upload) async {
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

      // Update status to uploading
      upload.status = UploadStatus.uploading;
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
      print('📤 Uploading ${upload.id} to $apiUrl/api/upload');
      final response = await _dio.post(
        '$apiUrl/api/upload',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
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
        upload.status = UploadStatus.failed;
        upload.errorMessage = 'Server returned ${response.statusCode}';
        upload.retryCount++;
        await HiveService.updateUpload(upload);
        return false;
      }
    } on DioException catch (e) {
      print('❌ Upload failed (DioException): ${e.message}');
      upload.status = UploadStatus.failed;
      upload.errorMessage = e.message ?? 'Network error';
      upload.retryCount++;
      await HiveService.updateUpload(upload);
      return false;
    } catch (e) {
      print('❌ Upload failed (Exception): $e');
      upload.status = UploadStatus.failed;
      upload.errorMessage = e.toString();
      upload.retryCount++;
      await HiveService.updateUpload(upload);
      return false;
    }
  }

  // Process all pending uploads
  Future<Map<String, int>> processQueue() async {
    print('🔄 Processing upload queue...');
    
    if (!await hasConnection()) {
      print('📡 No internet connection');
      return {'total': 0, 'success': 0, 'failed': 0};
    }

    final pending = HiveService.getPendingUploads();
    print('📋 Found ${pending.length} pending uploads');

    int successCount = 0;
    int failedCount = 0;

    for (final upload in pending) {
      // Skip if retry count exceeds max retries (5)
      if (upload.retryCount >= 5) {
        print('⏭️  Skipping ${upload.id} (max retries reached)');
        continue;
      }

      final success = await uploadImage(upload);
      if (success) {
        successCount++;
      } else {
        failedCount++;
      }
    }

    print('✨ Queue processing complete: $successCount succeeded, $failedCount failed');
    return {
      'total': pending.length,
      'success': successCount,
      'failed': failedCount,
    };
  }

  // Retry a specific upload
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

    return await uploadImage(upload);
  }

  // Retry all failed uploads
  Future<void> retryAllFailed() async {
    final failed = HiveService.getAllUploads()
        .where((u) => u.status == UploadStatus.failed)
        .toList();
    
    print('🔄 Retrying ${failed.length} failed uploads');
    
    for (final upload in failed) {
      upload.status = UploadStatus.pending;
      upload.errorMessage = null;
      await HiveService.updateUpload(upload);
    }

    await processQueue();
  }
}

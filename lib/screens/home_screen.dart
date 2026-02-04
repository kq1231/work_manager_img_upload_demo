import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:work_manager_img_upload_demo/services/workmanager_service.dart';
import '../models/pending_upload.dart';
import '../services/hive_service.dart';
import '../services/upload_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  final UploadService _uploadService = UploadService();
  final Uuid _uuid = const Uuid();
  final TextEditingController _apiUrlController = TextEditingController();
  final TextEditingController _patientIdController = TextEditingController();
  final TextEditingController _woundIdController = TextEditingController();

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _apiUrlController.text = HiveService.getApiUrl();
    _patientIdController.text = 'PATIENT_001';
    _woundIdController.text = 'WOUND_001';
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    _patientIdController.dispose();
    _woundIdController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (image != null) {
        await _processImage(image);
      }
    } catch (e) {
      _showSnackBar('Error picking image: $e', isError: true);
    }
  }

  Future<void> _processImage(XFile image) async {
    setState(() => _isProcessing = true);

    try {
      // Copy image to app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = '${_uuid.v4()}.jpg';
      final savedPath = '${appDir.path}/$fileName';
      await File(image.path).copy(savedPath);

      // Create pending upload
      final upload = PendingUpload(
        id: _uuid.v4(),
        imagePath: savedPath,
        patientId: _patientIdController.text,
        woundId: _woundIdController.text,
        createdAt: DateTime.now(),
      );

      // Save to Hive
      await HiveService.addUpload(upload);

      // Try immediate upload if online
      final hasConnection = await _uploadService.hasConnection();
      if (hasConnection) {
        _showSnackBar('Uploading image...', isError: false);
        // This is a foreground user action, don't increment retry count
        final success = await _uploadService.uploadImage(
          upload,
          isBackgroundTask: false,
        );

        if (success) {
          _showSnackBar('✅ Upload successful!', isError: false);
        } else {
          _showSnackBar('⏳ Queued for background upload', isError: false);
        }
      } else {
        _showSnackBar(
          '📡 Offline - queued for background upload',
          isError: false,
        );
      }

      setState(() {});
    } catch (e) {
      _showSnackBar('Error processing image: $e', isError: true);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _retryAll() async {
    setState(() => _isProcessing = true);

    try {
      final results = await _uploadService.retryAllFailed();
      if (results['total'] == 0) {
        _showSnackBar('No failed uploads to retry', isError: false);
      } else {
        _showSnackBar(
          '✅ ${results['success']}/${results['total']} retries succeeded',
          isError: false,
        );
      }
      setState(() {});
    } catch (e) {
      _showSnackBar('Error retrying: $e', isError: true);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _processQueue() async {
    setState(() => _isProcessing = true);

    try {
      // This is a foreground user action, don't increment retry count
      final results = await _uploadService.processQueue(
        isBackgroundTask: false,
      );
      _showSnackBar(
        '✅ ${results['success']}/${results['total']} uploads succeeded',
        isError: false,
      );
      setState(() {});
    } catch (e) {
      _showSnackBar('Error processing queue: $e', isError: true);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Uploads?'),
        content: const Text(
          'This will remove all pending uploads and delete their image files.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Delete all image files
      final uploads = HiveService.getAllUploads();
      for (final upload in uploads) {
        try {
          final file = File(upload.imagePath);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          //
        }
      }

      await HiveService.clearAllUploads();
      setState(() {});
      _showSnackBar('All uploads cleared', isError: false);
    }
  }

  Future<void> _saveApiUrl() async {
    await HiveService.setApiUrl(_apiUrlController.text);
    _showSnackBar('API URL saved', isError: false);
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Color _getStatusColor(UploadStatus status) {
    switch (status) {
      case UploadStatus.pending:
        return Colors.orange;
      case UploadStatus.failed:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(UploadStatus status) {
    switch (status) {
      case UploadStatus.pending:
        return Icons.schedule;
      case UploadStatus.failed:
        return Icons.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uploads = HiveService.getAllUploads();
    final pendingCount = uploads
        .where((u) => u.status == UploadStatus.pending)
        .length;
    final failedCount = uploads
        .where((u) => u.status == UploadStatus.failed)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Upload Demo'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (pendingCount > 0 || failedCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Row(
                  children: [
                    if (pendingCount > 0)
                      Chip(
                        label: Text(
                          '$pendingCount pending',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    if (pendingCount > 0 && failedCount > 0)
                      const SizedBox(width: 8),
                    if (failedCount > 0)
                      Chip(
                        label: Text(
                          '$failedCount failed',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // API URL Configuration
          Container(
            color: Colors.grey[100],
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'API Configuration',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _apiUrlController,
                        decoration: const InputDecoration(
                          labelText: 'API URL',
                          hintText: 'http://192.168.1.100:5000',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _saveApiUrl,
                      child: const Text('Save'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _patientIdController,
                        decoration: const InputDecoration(
                          labelText: 'Patient ID',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _woundIdController,
                        decoration: const InputDecoration(
                          labelText: 'Wound ID',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing
                        ? null
                        : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing
                        ? null
                        : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Queue Management Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing || pendingCount == 0
                        ? null
                        : _processQueue,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Process Queue'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing || failedCount == 0
                        ? null
                        : _retryAll,
                    icon: const Icon(Icons.replay),
                    label: const Text('Retry Failed'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Clear All Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isProcessing || uploads.isEmpty ? null : _clearAll,
                icon: const Icon(Icons.delete_forever),
                label: const Text('Clear All'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Test Background Task Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isProcessing || pendingCount == 0
                    ? null
                    : () async {
                        await WorkManagerService.registerOneOffTask();
                        _showSnackBar(
                          'Background task scheduled',
                          isError: false,
                        );
                      },
                icon: const Icon(Icons.timer),
                label: const Text('Test Background Task'),
              ),
            ),
          ),

          const Divider(height: 32),

          // Upload List Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Upload Queue (${uploads.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Failed: $failedCount',
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Upload List
          Expanded(
            child: uploads.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_upload, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No uploads yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Take a photo or pick from gallery to start',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: uploads.length,
                    itemBuilder: (context, index) {
                      final upload = uploads[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getStatusColor(upload.status),
                            child: Icon(
                              _getStatusIcon(upload.status),
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            '${upload.patientId} / ${upload.woundId}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_getStatusDescription(upload)),
                              if (upload.retryCount > 0)
                                Text(
                                  'Attempts: ${upload.retryCount}/5',
                                  style: TextStyle(
                                    color: upload.retryCount >= 4
                                        ? Colors.red
                                        : Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (upload.errorMessage != null)
                                Text(
                                  'Last error: ${upload.errorMessage}',
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 11,
                                  ),
                                ),
                              Text(
                                'Created: ${_formatDateTime(upload.createdAt)}',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                          trailing: upload.status == UploadStatus.failed
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.replay,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () async {
                                    setState(() => _isProcessing = true);
                                    await _uploadService.retryUpload(upload.id);
                                    setState(() => _isProcessing = false);
                                  },
                                )
                              : null,
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Info
          Container(
            color: Colors.grey[200],
            padding: const EdgeInsets.all(8),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 16),
                SizedBox(width: 8),
                Text(
                  'Background sync runs every 15 minutes',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }

  String _getStatusDescription(PendingUpload upload) {
    if (upload.status == UploadStatus.failed) {
      return 'Failed after 5 attempts - tap retry';
    } else if (upload.retryCount > 0) {
      return 'Pending retry (attempt ${upload.retryCount + 1}/5)';
    } else {
      return 'Pending upload';
    }
  }
}

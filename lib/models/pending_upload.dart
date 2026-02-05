import 'dart:typed_data';
import 'package:hive/hive.dart';

part 'pending_upload.g.dart';

@HiveType(typeId: 0)
enum UploadStatus {
  @HiveField(0)
  pending,
  
  @HiveField(1)
  failed, // Mark as failed if max retries reached
}

@HiveType(typeId: 1)
class PendingUpload extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final Uint8List imageBytes;

  @HiveField(2)
  final String patientId;

  @HiveField(3)
  final String woundId;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  int retryCount;

  @HiveField(6)
  UploadStatus status;

  @HiveField(7)
  String? errorMessage;

  @HiveField(8)
  DateTime? lastAttempt;

  @HiveField(9)
  final String fileName;

  PendingUpload({
    required this.id,
    required this.imageBytes,
    required this.fileName,
    required this.patientId,
    required this.woundId,
    required this.createdAt,
    this.retryCount = 0,
    this.status = UploadStatus.pending,
    this.errorMessage,
    this.lastAttempt,
  });

  @override
  String toString() {
    return 'PendingUpload(id: $id, patientId: $patientId, woundId: $woundId, status: $status, retryCount: $retryCount)';
  }
}

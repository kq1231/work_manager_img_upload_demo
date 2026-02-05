// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_upload.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PendingUploadAdapter extends TypeAdapter<PendingUpload> {
  @override
  final int typeId = 1;

  @override
  PendingUpload read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PendingUpload(
      id: fields[0] as String,
      imageBytes: fields[1] as Uint8List,
      fileName: fields[9] as String,
      patientId: fields[2] as String,
      woundId: fields[3] as String,
      createdAt: fields[4] as DateTime,
      retryCount: fields[5] as int,
      status: fields[6] as UploadStatus,
      errorMessage: fields[7] as String?,
      lastAttempt: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, PendingUpload obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.imageBytes)
      ..writeByte(2)
      ..write(obj.patientId)
      ..writeByte(3)
      ..write(obj.woundId)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.retryCount)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.errorMessage)
      ..writeByte(8)
      ..write(obj.lastAttempt)
      ..writeByte(9)
      ..write(obj.fileName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingUploadAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UploadStatusAdapter extends TypeAdapter<UploadStatus> {
  @override
  final int typeId = 0;

  @override
  UploadStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return UploadStatus.pending;
      case 1:
        return UploadStatus.failed;
      default:
        return UploadStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, UploadStatus obj) {
    switch (obj) {
      case UploadStatus.pending:
        writer.writeByte(0);
        break;
      case UploadStatus.failed:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UploadStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

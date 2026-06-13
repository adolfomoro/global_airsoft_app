import 'package:global_airsoft_app/src/features/files/domain/models/direct_file_upload_source.dart';

final class InitiateDirectFileUploadInputDto {
  const InitiateDirectFileUploadInputDto({
    required this.fileName,
    required this.contentType,
    required this.sizeBytes,
    this.expectedChecksum,
    this.checksumAlgorithm,
    this.idempotencyKey,
  });

  final String fileName;
  final String contentType;
  final int sizeBytes;
  final String? expectedChecksum;
  final String? checksumAlgorithm;
  final String? idempotencyKey;

  factory InitiateDirectFileUploadInputDto.fromSource(
    DirectFileUploadSource source, {
    String? expectedChecksum,
    String? checksumAlgorithm,
    String? idempotencyKey,
  }) {
    return InitiateDirectFileUploadInputDto(
      fileName: source.fileName,
      contentType: source.contentType,
      sizeBytes: source.sizeBytes,
      expectedChecksum: expectedChecksum,
      checksumAlgorithm: checksumAlgorithm,
      idempotencyKey: idempotencyKey,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'fileName': fileName,
      'contentType': contentType,
      'sizeBytes': sizeBytes,
      if (expectedChecksum != null) 'expectedChecksum': expectedChecksum,
      if (checksumAlgorithm != null) 'checksumAlgorithm': checksumAlgorithm,
      if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
    };
  }
}

import 'package:global_airsoft_app/src/features/files/domain/models/direct_file_upload_status.dart';

final class DirectFileUploadStatusDto {
  const DirectFileUploadStatusDto({
    required this.uploadSessionId,
    required this.fileId,
    required this.uploadStatus,
    required this.isComplete,
    required this.isTerminal,
    required this.expiresAtUtc,
    this.failureReason,
    this.confirmedAtUtc,
  });

  final String uploadSessionId;
  final String fileId;
  final String uploadStatus;
  final bool isComplete;
  final bool isTerminal;
  final String? failureReason;
  final DateTime? confirmedAtUtc;
  final DateTime expiresAtUtc;

  factory DirectFileUploadStatusDto.fromJson(Map<String, dynamic> json) {
    final Object? uploadSessionId = json['uploadSessionId'];
    final Object? fileId = json['fileId'];
    final Object? uploadStatus = json['uploadStatus'];
    final Object? isComplete = json['isComplete'];
    final Object? isTerminal = json['isTerminal'];
    final Object? failureReason = json['failureReason'];
    final Object? confirmedAtUtc = json['confirmedAtUtc'];
    final Object? expiresAtUtc = json['expiresAtUtc'];

    if (uploadSessionId is! String ||
        fileId is! String ||
        uploadStatus is! String ||
        isComplete is! bool ||
        isTerminal is! bool ||
        expiresAtUtc is! String) {
      throw const FormatException('Invalid direct upload status payload.');
    }

    final DateTime? parsedExpiration = DateTime.tryParse(expiresAtUtc);
    if (parsedExpiration == null) {
      throw const FormatException('Invalid direct upload status expiration.');
    }

    DateTime? parsedConfirmation;
    if (confirmedAtUtc != null) {
      if (confirmedAtUtc is! String) {
        throw const FormatException('Invalid direct upload confirmation date.');
      }

      parsedConfirmation = DateTime.tryParse(confirmedAtUtc);
      if (parsedConfirmation == null) {
        throw const FormatException('Invalid direct upload confirmation date.');
      }
    }

    return DirectFileUploadStatusDto(
      uploadSessionId: uploadSessionId,
      fileId: fileId,
      uploadStatus: uploadStatus,
      isComplete: isComplete,
      isTerminal: isTerminal,
      failureReason: failureReason is String ? failureReason : null,
      confirmedAtUtc: parsedConfirmation?.toUtc(),
      expiresAtUtc: parsedExpiration.toUtc(),
    );
  }

  DirectFileUploadStatus toDomain() {
    if (uploadSessionId.trim().isEmpty || fileId.trim().isEmpty) {
      throw const FormatException('Invalid direct upload status identifiers.');
    }

    final DirectFileUploadStatusValue status =
        DirectFileUploadStatusValue.parse(uploadStatus);
    if (status == DirectFileUploadStatusValue.unknown) {
      throw const FormatException('Invalid direct upload status.');
    }

    return DirectFileUploadStatus(
      uploadSessionId: uploadSessionId.trim(),
      fileId: fileId.trim(),
      status: status,
      isComplete: isComplete,
      isTerminal: isTerminal,
      failureReason: failureReason?.trim(),
      confirmedAtUtc: confirmedAtUtc,
      expiresAtUtc: expiresAtUtc,
    );
  }
}

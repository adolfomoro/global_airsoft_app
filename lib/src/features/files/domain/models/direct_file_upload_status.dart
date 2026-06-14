enum DirectFileUploadStatusValue {
  pending,
  uploaded,
  failed,
  expired,
  unknown;

  bool get isComplete => this == DirectFileUploadStatusValue.uploaded;

  bool get isTerminal {
    return this == DirectFileUploadStatusValue.uploaded ||
        this == DirectFileUploadStatusValue.failed ||
        this == DirectFileUploadStatusValue.expired;
  }

  static DirectFileUploadStatusValue parse(String value) {
    return switch (value.trim().toLowerCase()) {
      'pending' => DirectFileUploadStatusValue.pending,
      'uploaded' => DirectFileUploadStatusValue.uploaded,
      'failed' => DirectFileUploadStatusValue.failed,
      'expired' => DirectFileUploadStatusValue.expired,
      _ => DirectFileUploadStatusValue.unknown,
    };
  }
}

final class DirectFileUploadStatus {
  const DirectFileUploadStatus({
    required this.uploadSessionId,
    required this.fileId,
    required this.status,
    required this.isComplete,
    required this.isTerminal,
    required this.expiresAtUtc,
    this.failureReason,
    this.confirmedAtUtc,
  });

  final String uploadSessionId;
  final String fileId;
  final DirectFileUploadStatusValue status;
  final bool isComplete;
  final bool isTerminal;
  final String? failureReason;
  final DateTime? confirmedAtUtc;
  final DateTime expiresAtUtc;
}

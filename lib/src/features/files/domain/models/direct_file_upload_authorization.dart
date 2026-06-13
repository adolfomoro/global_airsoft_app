final class DirectFileUploadAuthorization {
  const DirectFileUploadAuthorization({
    required this.uploadSessionId,
    required this.fileId,
    required this.uploadUrl,
    required this.method,
    required this.requiredHeaders,
    required this.expiresAtUtc,
    required this.maxFileSizeBytes,
  });

  final String uploadSessionId;
  final String fileId;
  final Uri uploadUrl;
  final String method;
  final Map<String, String> requiredHeaders;
  final DateTime expiresAtUtc;
  final int maxFileSizeBytes;

  bool get isExpired {
    return !DateTime.now().toUtc().isBefore(expiresAtUtc);
  }
}

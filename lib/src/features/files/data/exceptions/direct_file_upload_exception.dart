final class DirectFileUploadException implements Exception {
  const DirectFileUploadException({
    required this.message,
    this.statusCode,
    this.cause,
  });

  final String message;
  final int? statusCode;
  final Object? cause;

  @override
  String toString() {
    return 'DirectFileUploadException(message: $message, statusCode: $statusCode)';
  }
}

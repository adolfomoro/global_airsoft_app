final class DeviceRegistrationException implements Exception {
  DeviceRegistrationException({
    required this.message,
    this.statusCode,
    this.cause,
  });

  final String message;
  final int? statusCode;
  final Object? cause;

  @override
  String toString() {
    final String status = statusCode != null
        ? ' (statusCode: $statusCode)'
        : '';
    return 'DeviceRegistrationException: $message$status';
  }
}

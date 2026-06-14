import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';

final class RemoteImageAccessException implements Exception {
  const RemoteImageAccessException({
    required this.message,
    this.messageKey = AppLocaleKeys.commonRemoteImageLoadFailed,
    this.statusCode,
    this.cause,
  });

  final String message;
  final String messageKey;
  final int? statusCode;
  final Object? cause;

  @override
  String toString() {
    return 'RemoteImageAccessException(message: $message, statusCode: $statusCode)';
  }
}

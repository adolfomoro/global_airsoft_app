import 'package:global_airsoft_app/src/core/network/api_exception.dart';

final class AuthSecurityHandledException extends ApiException {
  const AuthSecurityHandledException({
    required super.message,
    super.statusCode,
    super.code,
    super.details,
    super.data,
    super.validationErrors = const [],
    super.cause,
    super.isFallbackMessage,
  });

  String get reason => code ?? '';

  factory AuthSecurityHandledException.fromApiException(
    ApiException error, {
    required String fallbackMessage,
  }) {
    final String backendMessage = error.message.trim();
    final bool hasBackendMessage =
        !error.isFallbackMessage && backendMessage.isNotEmpty;

    return AuthSecurityHandledException(
      message: hasBackendMessage ? backendMessage : fallbackMessage,
      statusCode: error.statusCode,
      code: error.code,
      details: error.details,
      data: error.data,
      validationErrors: error.validationErrors,
      cause: error.cause,
      isFallbackMessage: !hasBackendMessage,
    );
  }
}

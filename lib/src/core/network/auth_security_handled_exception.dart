import 'package:global_airsoft_app/src/core/network/api_exception.dart';
import 'package:global_airsoft_app/src/core/network/message_resolution_policy.dart';

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

  @override
  MessageResolutionPolicy get messageResolutionPolicy =>
      const MessageResolutionPolicy(
        overrideProtection: MessageOverrideProtection.lockFailureMessage,
        presentationBehavior:
            MessagePresentationBehavior.alreadyPresentedUpstream,
      );

  factory AuthSecurityHandledException.fromApiException(
    ApiException error, {
    required String fallbackMessage,
    bool preferFallbackMessage = false,
  }) {
    final String backendMessage = error.message.trim();
    final bool hasBackendMessage =
        !preferFallbackMessage &&
        !error.isFallbackMessage &&
        backendMessage.isNotEmpty;

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

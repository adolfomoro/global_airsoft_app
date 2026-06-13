import 'package:global_airsoft_app/src/core/network/abp_error_response.dart';
import 'package:global_airsoft_app/src/core/network/api_exception.dart';
import 'package:global_airsoft_app/src/core/network/message_resolution_policy.dart';

final class AuthenticationException implements Exception, ApiExceptionSource {
  AuthenticationException({
    required this.failure,
    this.messageOverride,
    this.messageOverrideBehavior = MessageOverrideBehavior.useAsFallback,
  });

  final ApiException failure;
  final String? messageOverride;
  final MessageOverrideBehavior messageOverrideBehavior;

  @override
  ApiException get apiException => failure;

  String? get message {
    return failure.resolveMessage(
      overrideMessage: messageOverride,
      overrideBehavior: messageOverrideBehavior,
    );
  }

  List<AbpValidationError> get validationErrors => failure.validationErrors;

  factory AuthenticationException.fromApiException(
    ApiException error, {
    String? messageOverride,
    MessageOverrideBehavior messageOverrideBehavior =
        MessageOverrideBehavior.useAsFallback,
  }) {
    return AuthenticationException(
      failure: error.toTypedException(),
      messageOverride: messageOverride,
      messageOverrideBehavior: messageOverrideBehavior,
    );
  }

  factory AuthenticationException.fromAbpException(
    AbpApiException error, {
    String? messageOverride,
    MessageOverrideBehavior messageOverrideBehavior =
        MessageOverrideBehavior.useAsFallback,
  }) {
    return AuthenticationException(
      failure: error.toTypedException(),
      messageOverride: messageOverride,
      messageOverrideBehavior: messageOverrideBehavior,
    );
  }

  @override
  String toString() => message ?? '';
}

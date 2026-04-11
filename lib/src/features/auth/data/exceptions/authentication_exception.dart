import 'package:global_airsoft_app/src/core/network/abp_error_response.dart';
import 'package:global_airsoft_app/src/core/network/api_exception.dart';

final class AuthenticationException implements Exception {
  AuthenticationException({required this.failure, this.messageOverride});

  final ApiException failure;
  final String? messageOverride;

  String? get message {
    final isValidationApiException = failure is ValidationApiException;
    if (!isValidationApiException) {
      return messageOverride ?? failure.message;
    }
    return null;
  }

  List<AbpValidationError> get validationErrors => failure.validationErrors;

  factory AuthenticationException.fromApiException(
    ApiException error, {
    String? messageOverride,
  }) {
    return AuthenticationException(
      failure: error.toTypedException(),
      messageOverride: messageOverride,
    );
  }

  factory AuthenticationException.fromAbpException(
    AbpApiException error, {
    String? messageOverride,
  }) {
    return AuthenticationException(
      failure: error.toTypedException(),
      messageOverride: messageOverride,
    );
  }

  @override
  String toString() => message ?? '';
}

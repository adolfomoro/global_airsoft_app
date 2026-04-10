import 'package:global_airsoft_app/src/core/network/abp_error_response.dart';
import 'package:global_airsoft_app/src/core/network/api_exception.dart';

final class AuthenticationException implements Exception {
  AuthenticationException({required this.failure});

  final ApiException failure;

  String? get message {
    final isValidationApiException = failure is ValidationApiException;
    if (!isValidationApiException) {
      return failure.message;
    }
    return null;
  }

  List<AbpValidationError> get validationErrors => failure.validationErrors;

  factory AuthenticationException.fromApiException(ApiException error) {
    return AuthenticationException(failure: error.toTypedException());
  }

  factory AuthenticationException.fromAbpException(AbpApiException error) {
    return AuthenticationException(failure: error.toTypedException());
  }

  @override
  String toString() => message ?? '';
}

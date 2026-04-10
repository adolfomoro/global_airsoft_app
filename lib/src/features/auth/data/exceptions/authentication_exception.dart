import 'package:global_airsoft_app/src/core/network/api_exception.dart';

final class AuthenticationException implements Exception {
  AuthenticationException({required this.message});

  final String message;

  factory AuthenticationException.fromApiException(ApiException error) {
    return AuthenticationException(message: error.message);
  }

  factory AuthenticationException.fromAbpException(AbpApiException error) {
    return AuthenticationException(message: error.message);
  }

  @override
  String toString() => message;
}

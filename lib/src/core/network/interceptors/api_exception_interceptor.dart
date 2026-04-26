import 'package:dio/dio.dart';
import 'package:global_airsoft_app/src/core/network/api_exception.dart';
import 'package:global_airsoft_app/src/core/network/api_exception_formatter.dart';
import 'package:global_airsoft_app/src/core/network/auth_security_handled_exception.dart';

final class ApiExceptionInterceptor extends Interceptor {
  ApiExceptionInterceptor({
    required Future<String> Function() badResponseFallbackMessageResolver,
  }) : _badResponseFallbackMessageResolver = badResponseFallbackMessageResolver;

  final Future<String> Function() _badResponseFallbackMessageResolver;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.error is AuthSecurityHandledException ||
        err.error is ApiException) {
      handler.next(err);
      return;
    }

    final String badResponseFallbackMessage =
        err.type == DioExceptionType.badResponse
        ? await _resolveBadResponseFallbackMessage()
        : ApiException.defaultBadResponseFallbackMessage;

    final ApiException apiException = ApiExceptionFormatter.toTypedException(
      err,
      badResponseFallbackMessage: badResponseFallbackMessage,
    );

    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: apiException,
        message: apiException.message,
      ),
    );
  }

  Future<String> _resolveBadResponseFallbackMessage() async {
    try {
      final String localizedMessage =
          await _badResponseFallbackMessageResolver();
      final String normalizedMessage = localizedMessage.trim();
      if (normalizedMessage.isNotEmpty) {
        return normalizedMessage;
      }
    } catch (_) {
      // Fall back to the built-in English string below.
    }

    return ApiException.defaultBadResponseFallbackMessage;
  }
}

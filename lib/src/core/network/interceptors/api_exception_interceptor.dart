import 'package:dio/dio.dart';
import 'package:global_airsoft_app/src/core/network/api_exception.dart';
import 'package:global_airsoft_app/src/core/network/api_exception_formatter.dart';
import 'package:global_airsoft_app/src/core/network/auth_security_handled_exception.dart';

final class ApiExceptionInterceptor extends Interceptor {
  ApiExceptionInterceptor({
    required Future<ApiExceptionLocalizedMessages> Function()
    localizedMessagesResolver,
  }) : _localizedMessagesResolver = localizedMessagesResolver;

  final Future<ApiExceptionLocalizedMessages> Function()
  _localizedMessagesResolver;

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

    final ApiExceptionLocalizedMessages localizedMessages =
        await _resolveLocalizedMessages();

    final ApiException apiException = ApiExceptionFormatter.toTypedException(
      err,
      localizedMessages: localizedMessages,
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

  Future<ApiExceptionLocalizedMessages> _resolveLocalizedMessages() async {
    try {
      return await _localizedMessagesResolver();
    } catch (_) {
      return const ApiExceptionLocalizedMessages();
    }
  }
}

import 'package:dio/dio.dart';
import 'package:global_airsoft_app/src/core/logging/app_logger.dart';
import 'package:global_airsoft_app/src/core/network/api_exception.dart';
import 'package:global_airsoft_app/src/core/network/api_exception_diagnostics.dart';
import 'package:global_airsoft_app/src/core/network/api_exception_formatter.dart';
import 'package:global_airsoft_app/src/core/network/auth_security_handled_exception.dart';

final class ApiExceptionInterceptor extends Interceptor {
  ApiExceptionInterceptor({
    required AppLogger logger,
    required Future<ApiExceptionLocalizedMessages> Function()
    localizedMessagesResolver,
  }) : _logger = logger,
       _localizedMessagesResolver = localizedMessagesResolver;

  final AppLogger _logger;
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
    if (ApiExceptionDiagnostics.shouldLog(apiException)) {
      _logger.error(
        'Unexpected API failure returned by backend.',
        error: apiException,
        stackTrace: err.stackTrace,
        attributes: ApiExceptionDiagnostics.buildLogAttributes(
          apiException,
          requestOptions: err.requestOptions,
        ),
      );
    }

    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: apiException,
        stackTrace: err.stackTrace,
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

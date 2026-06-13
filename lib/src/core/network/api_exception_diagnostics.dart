import 'package:dio/dio.dart';
import 'package:global_airsoft_app/src/core/network/api_exception.dart';

final class ApiExceptionDiagnostics {
  ApiExceptionDiagnostics._();

  static const String correlationIdLabel = 'Correlation ID';

  static ApiException? extractApiException(Object? source) {
    if (source is ApiException) {
      return source;
    }

    if (source is ApiExceptionSource) {
      return source.apiException;
    }

    return null;
  }

  static String formatMessageForDisplay(String message, {Object? source}) {
    final String normalizedMessage = message.trim();
    if (normalizedMessage.isEmpty) {
      return '';
    }

    final ApiException? apiException = extractApiException(source);
    final String? correlationIdLine = apiException == null
        ? null
        : buildCorrelationIdLine(apiException);

    if (correlationIdLine == null) {
      return normalizedMessage;
    }

    return '$normalizedMessage\n$correlationIdLine';
  }

  static String? buildCorrelationIdLine(ApiException exception) {
    final String? correlationId = _normalizeValue(exception.correlationId);
    if (!exception.isUnexpectedFailure || correlationId == null) {
      return null;
    }

    return '$correlationIdLabel: $correlationId';
  }

  static bool shouldLog(ApiException exception) {
    return exception.isUnexpectedFailure;
  }

  static Map<String, Object?> buildLogAttributes(
    ApiException exception, {
    RequestOptions? requestOptions,
  }) {
    final Map<String, Object?> attributes = <String, Object?>{
      'api_exception_type': exception.runtimeType.toString(),
      'api_is_fallback_message': exception.isFallbackMessage,
      'api_is_unexpected_failure': exception.isUnexpectedFailure,
    };

    final String? correlationId = _normalizeValue(exception.correlationId);
    if (correlationId != null) {
      attributes['correlation_id'] = correlationId;
    }

    final int? statusCode = exception.statusCode;
    if (statusCode != null) {
      attributes['http_status_code'] = statusCode;
    }

    final String? errorCode = _normalizeValue(exception.code);
    if (errorCode != null) {
      attributes['api_error_code'] = errorCode;
    }

    if (requestOptions != null) {
      final String? method = _normalizeValue(requestOptions.method);
      final String? path = _normalizeValue(requestOptions.path);
      if (method != null) {
        attributes['http_method'] = method;
      }
      if (path != null) {
        attributes['http_path'] = path;
      }
    }

    return attributes;
  }

  static String? _normalizeValue(String? value) {
    final String normalized = value?.trim() ?? '';
    return normalized.isEmpty ? null : normalized;
  }
}

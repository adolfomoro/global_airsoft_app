import 'package:dio/dio.dart';
import 'package:global_airsoft_app/src/core/network/abp_error_response.dart';
import 'package:global_airsoft_app/src/core/network/api_exception.dart';

final class ApiExceptionFormatter {
  const ApiExceptionFormatter._();

  static ApiException toTypedException(
    DioException err, {
    ApiExceptionLocalizedMessages localizedMessages =
        const ApiExceptionLocalizedMessages(),
  }) {
    final Response<dynamic>? response = err.response;
    if (_isAbpFormatted(response)) {
      final Map<String, dynamic>? normalized = _normalizeJsonMap(
        response?.data,
      );
      if (normalized != null) {
        try {
          final AbpErrorResponse parsed = AbpErrorResponse.fromJson(
            normalized,
            validationErrorFallbackMessage:
                localizedMessages.validationErrorMessage,
          );
          final AbpApiException exception = AbpApiException.fromAbpPayload(
            payload: parsed.error,
            statusCode: response?.statusCode,
            cause: err,
            correlationId: ApiException.extractCorrelationIdFromHeaders(
              response?.headers,
            ),
            badResponseFallbackMessage:
                localizedMessages.badResponseFallbackMessage,
          );
          return exception.toTypedException();
        } on FormatException {
          // Fall through and map to generic API exception.
        }
      }
    }

    return ApiException.fromDioException(
      err,
      localizedMessages: localizedMessages,
    ).toTypedException();
  }

  static const Set<String> _abpErrorFormatHeaderNames = <String>{
    'abperrorformat',
    '_abperrorformat',
  };

  static bool _isAbpFormatted(Response<dynamic>? response) {
    if (response == null) {
      return false;
    }

    final Headers headers = response.headers;
    final Map<String, List<String>> headerMap = headers.map;

    for (final MapEntry<String, List<String>> entry in headerMap.entries) {
      final String normalizedKey = entry.key.toLowerCase();
      if (_abpErrorFormatHeaderNames.contains(normalizedKey)) {
        final bool hasExpectedValue = entry.value.any((String value) {
          return value.trim().toLowerCase() == 'true';
        });
        if (hasExpectedValue) {
          return true;
        }
      }
    }

    return false;
  }

  static Map<String, dynamic>? _normalizeJsonMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      final Map<String, dynamic> normalized = <String, dynamic>{};
      for (final MapEntry<Object?, Object?> entry in value.entries) {
        final Object? key = entry.key;
        if (key is String) {
          normalized[key] = entry.value;
        }
      }
      return normalized;
    }

    return null;
  }
}

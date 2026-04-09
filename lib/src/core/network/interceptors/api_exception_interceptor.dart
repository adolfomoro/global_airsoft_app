import 'package:dio/dio.dart';
import 'package:global_airsoft_app/src/core/network/abp_error_response.dart';
import 'package:global_airsoft_app/src/core/network/api_exception.dart';

final class ApiExceptionInterceptor extends Interceptor {
  static const String _abpErrorHeaderName = '_abperrorformat';
  static const String _abpErrorHeaderExpectedValue = 'true';

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final Response<dynamic>? response = err.response;
    final bool isAbpFormatted = _isAbpFormatted(response);
    if (isAbpFormatted) {
      final Object? data = response?.data;
      final Map<String, dynamic>? normalized = _normalizeJsonMap(data);
      if (normalized != null) {
        try {
          final AbpErrorResponse parsed = AbpErrorResponse.fromJson(normalized);
          final AbpApiException exception = AbpApiException.fromAbpPayload(
            payload: parsed.error,
            statusCode: response?.statusCode,
            cause: err,
          );
          handler.reject(err.copyWith(error: exception));
          return;
        } on FormatException {
          // Fall through and map to generic API exception.
        }
      }
    }

    final ApiException fallbackException = ApiException.fromDioException(err);
    handler.reject(err.copyWith(error: fallbackException));
  }

  bool _isAbpFormatted(Response<dynamic>? response) {
    if (response == null) {
      return false;
    }

    final Headers headers = response.headers;
    final Map<String, List<String>> headerMap = headers.map;

    for (final MapEntry<String, List<String>> entry in headerMap.entries) {
      final String normalizedKey = entry.key.toLowerCase();
      if (normalizedKey == _abpErrorHeaderName) {
        final bool hasExpectedValue = entry.value.any((String value) {
          return value.trim().toLowerCase() == _abpErrorHeaderExpectedValue;
        });
        if (hasExpectedValue) {
          return true;
        }
      }
    }

    return false;
  }

  Map<String, dynamic>? _normalizeJsonMap(Object? value) {
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

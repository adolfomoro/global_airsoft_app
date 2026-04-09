import 'package:dio/dio.dart';
import 'package:global_airsoft_app/src/core/network/abp_error_response.dart';

class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.details,
    this.validationErrors = const <AbpValidationError>[],
    this.cause,
  });

  final String message;
  final int? statusCode;
  final String? code;
  final String? details;
  final List<AbpValidationError> validationErrors;
  final Object? cause;

  factory ApiException.fromDioException(DioException exception) {
    final int? statusCode = exception.response?.statusCode;

    String message = 'Unexpected API error.';
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
        message = 'Connection timeout while calling API.';
      case DioExceptionType.sendTimeout:
        message = 'Send timeout while calling API.';
      case DioExceptionType.receiveTimeout:
        message = 'Receive timeout while calling API.';
      case DioExceptionType.badCertificate:
        message = 'Bad certificate from API endpoint.';
      case DioExceptionType.badResponse:
        message = 'API returned an invalid response.';
      case DioExceptionType.cancel:
        message = 'Request was cancelled.';
      case DioExceptionType.connectionError:
        message = 'Connection error while calling API.';
      case DioExceptionType.unknown:
        message = 'Unknown API error.';
    }

    return ApiException(
      message: message,
      statusCode: statusCode,
      cause: exception,
    );
  }

  @override
  String toString() {
    return 'ApiException(message: $message, statusCode: $statusCode, code: $code)';
  }
}

final class AbpApiException extends ApiException {
  const AbpApiException({
    required super.message,
    super.statusCode,
    super.code,
    super.details,
    super.validationErrors,
    super.cause,
  });

  factory AbpApiException.fromAbpPayload({
    required AbpErrorPayload payload,
    required int? statusCode,
    required Object? cause,
  }) {
    return AbpApiException(
      message: payload.message,
      statusCode: statusCode,
      code: payload.code,
      details: payload.details,
      validationErrors: payload.validationErrors,
      cause: cause,
    );
  }
}

import 'package:dio/dio.dart';
import 'package:global_airsoft_app/src/core/network/abp_error_response.dart';

class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.details,
    this.data,
    this.validationErrors = const <AbpValidationError>[],
    this.cause,
  });

  final String message;
  final int? statusCode;
  final String? code;
  final String? details;
  final Object? data;
  final List<AbpValidationError> validationErrors;
  final Object? cause;

  factory ApiException.fromDioException(DioException exception) {
    final int? statusCode = exception.response?.statusCode;
    final Object? responseData = exception.response?.data;
    final _ExtractedMessage extracted = _extractMessageFromResponse(
      responseData,
    );

    final String message = switch (exception.type) {
      DioExceptionType.connectionTimeout =>
        'Connection timeout while calling API.',
      DioExceptionType.sendTimeout => 'Send timeout while calling API.',
      DioExceptionType.receiveTimeout => 'Receive timeout while calling API.',
      DioExceptionType.badCertificate => 'Bad certificate from API endpoint.',
      DioExceptionType.badResponse =>
        extracted.message ?? 'API returned an invalid response.',
      DioExceptionType.cancel => 'Request was cancelled.',
      DioExceptionType.connectionError => 'Connection error while calling API.',
      DioExceptionType.unknown => 'Unknown API error.',
    };

    final String? details = exception.type == DioExceptionType.badResponse
        ? extracted.details
        : null;

    return ApiException(
      message: message,
      statusCode: statusCode,
      details: details,
      data: responseData,
      cause: exception,
    );
  }

  @override
  String toString() {
    return 'ApiException(message: $message, statusCode: $statusCode, code: $code)';
  }
}

final class _ExtractedMessage {
  const _ExtractedMessage({this.message, this.details});

  final String? message;
  final String? details;
}

_ExtractedMessage _extractMessageFromResponse(Object? responseData) {
  if (responseData is Map<String, dynamic>) {
    final String? message = (responseData['message'] as String?)?.trim();
    final String? details = (responseData['details'] as String?)?.trim();
    return _ExtractedMessage(
      message: message?.isNotEmpty == true ? message : null,
      details: details?.isNotEmpty == true ? details : null,
    );
  }

  if (responseData is String) {
    final String normalized = responseData.trim();
    if (normalized.isNotEmpty) {
      return _ExtractedMessage(message: normalized);
    }
  }

  return const _ExtractedMessage();
}

final class AbpApiException extends ApiException {
  const AbpApiException({
    required super.message,
    super.statusCode,
    super.code,
    super.details,
    super.data,
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
      data: payload.data,
      validationErrors: payload.validationErrors,
      cause: cause,
    );
  }
}

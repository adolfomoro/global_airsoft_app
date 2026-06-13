import 'package:dio/dio.dart';
import 'package:global_airsoft_app/src/core/network/abp_error_response.dart';
import 'package:global_airsoft_app/src/core/network/message_resolution_policy.dart';

abstract interface class ApiExceptionSource {
  ApiException get apiException;
}

final class ApiExceptionLocalizedMessages {
  static const String _defaultGenericMessage =
      ApiException.defaultBadResponseFallbackMessage;

  const ApiExceptionLocalizedMessages({
    this.badResponseFallbackMessage =
        ApiException.defaultBadResponseFallbackMessage,
    this.connectionTimeoutMessage = _defaultGenericMessage,
    this.sendTimeoutMessage = _defaultGenericMessage,
    this.receiveTimeoutMessage = _defaultGenericMessage,
    this.badCertificateMessage = _defaultGenericMessage,
    this.requestCancelledMessage = _defaultGenericMessage,
    this.connectionErrorMessage = _defaultGenericMessage,
    this.unknownErrorMessage = _defaultGenericMessage,
    this.validationErrorMessage = 'Validation error',
  });

  final String badResponseFallbackMessage;
  final String connectionTimeoutMessage;
  final String sendTimeoutMessage;
  final String receiveTimeoutMessage;
  final String badCertificateMessage;
  final String requestCancelledMessage;
  final String connectionErrorMessage;
  final String unknownErrorMessage;
  final String validationErrorMessage;
}

class ApiException implements Exception {
  static const String defaultBadResponseFallbackMessage =
      'An error occurred. Please try again later.';
  static const String correlationIdHeaderName = 'x-correlation-id';

  const ApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.details,
    this.data,
    this.validationErrors = const <AbpValidationError>[],
    this.cause,
    this.isFallbackMessage = false,
    this.correlationId,
    this.isUnexpectedFailure = false,
  });

  final String message;
  final int? statusCode;
  final String? code;
  final String? details;
  final Object? data;
  final List<AbpValidationError> validationErrors;
  final Object? cause;
  final bool isFallbackMessage;
  final String? correlationId;
  final bool isUnexpectedFailure;

  MessageResolutionPolicy get messageResolutionPolicy =>
      const MessageResolutionPolicy();

  bool get suppressesDuplicatePresentation {
    return messageResolutionPolicy.suppressesDuplicatePresentation;
  }

  String? resolveMessage({
    String? overrideMessage,
    MessageOverrideBehavior overrideBehavior =
        MessageOverrideBehavior.useAsFallback,
  }) {
    return messageResolutionPolicy.resolve(
      failureMessage: message,
      isFailureFallbackMessage: isFallbackMessage,
      overrideMessage: overrideMessage,
      overrideBehavior: overrideBehavior,
    );
  }

  factory ApiException.fromDioException(
    DioException exception, {
    ApiExceptionLocalizedMessages localizedMessages =
        const ApiExceptionLocalizedMessages(),
  }) {
    final int? statusCode = exception.response?.statusCode;
    final Object? responseData = exception.response?.data;
    final _ExtractedMessage extracted = _extractMessageFromResponse(
      responseData,
    );
    final String normalizedFallbackMessage =
        localizedMessages.badResponseFallbackMessage.trim().isNotEmpty
        ? localizedMessages.badResponseFallbackMessage.trim()
        : defaultBadResponseFallbackMessage;
    final bool hasBackendMessage = extracted.message != null;
    final bool isFallbackMessage = switch (exception.type) {
      DioExceptionType.badResponse => !hasBackendMessage,
      DioExceptionType.connectionTimeout => true,
      DioExceptionType.sendTimeout => true,
      DioExceptionType.receiveTimeout => true,
      DioExceptionType.badCertificate => true,
      DioExceptionType.cancel => true,
      DioExceptionType.connectionError => true,
      DioExceptionType.unknown => true,
    };

    final String message = switch (exception.type) {
      DioExceptionType.connectionTimeout =>
        localizedMessages.connectionTimeoutMessage,
      DioExceptionType.sendTimeout => localizedMessages.sendTimeoutMessage,
      DioExceptionType.receiveTimeout =>
        localizedMessages.receiveTimeoutMessage,
      DioExceptionType.badCertificate =>
        localizedMessages.badCertificateMessage,
      DioExceptionType.badResponse =>
        extracted.message ?? normalizedFallbackMessage,
      DioExceptionType.cancel => localizedMessages.requestCancelledMessage,
      DioExceptionType.connectionError =>
        localizedMessages.connectionErrorMessage,
      DioExceptionType.unknown => localizedMessages.unknownErrorMessage,
    };

    final String? details = exception.type == DioExceptionType.badResponse
        ? extracted.details
        : null;
    final String? correlationId = extractCorrelationIdFromHeaders(
      exception.response?.headers,
    );

    return ApiException(
      message: message,
      statusCode: statusCode,
      details: details,
      data: responseData,
      cause: exception,
      isFallbackMessage: isFallbackMessage,
      correlationId: correlationId,
    );
  }

  static String? extractCorrelationIdFromHeaders(Headers? headers) {
    if (headers == null) {
      return null;
    }

    for (final MapEntry<String, List<String>> entry in headers.map.entries) {
      if (entry.key.trim().toLowerCase() != correlationIdHeaderName) {
        continue;
      }

      for (final String value in entry.value) {
        final String normalized = value.trim();
        if (normalized.isNotEmpty) {
          return normalized;
        }
      }
    }

    return null;
  }

  @override
  String toString() {
    return 'ApiException(message: $message, statusCode: $statusCode, code: $code)';
  }

  ApiException toTypedException() {
    if (this is! AbpApiException && runtimeType != ApiException) {
      return this;
    }

    if (statusCode == 400 && validationErrors.isNotEmpty) {
      return ValidationApiException.fromApiException(this);
    }

    switch (statusCode) {
      case 401:
        return UnauthorizedApiException.fromApiException(this);
      case 403:
        return ForbiddenApiException.fromApiException(this);
      case 404:
        return NotFoundApiException.fromApiException(this);
      case 400:
        return UserFriendlyApiException.fromApiException(this);
      case 409:
        return UserFriendlyApiException.fromApiException(this);
      case 501:
        return NotImplementedApiException.fromApiException(this);
      default:
        if (statusCode != null && statusCode! >= 500) {
          return ServerApiException.fromApiException(this);
        }
        return UnknownApiException.fromApiException(this);
    }
  }
}

class ValidationApiException extends ApiException {
  const ValidationApiException({
    required super.message,
    super.statusCode,
    super.code,
    super.details,
    super.data,
    required super.validationErrors,
    super.cause,
    super.isFallbackMessage,
    super.correlationId,
    super.isUnexpectedFailure,
  });

  @override
  String? resolveMessage({
    String? overrideMessage,
    MessageOverrideBehavior overrideBehavior =
        MessageOverrideBehavior.useAsFallback,
  }) {
    return messageResolutionPolicy.resolve(
      failureMessage: overrideMessage?.trim() ?? '',
      isFailureFallbackMessage: isFallbackMessage,
      overrideMessage: overrideMessage,
      overrideBehavior: overrideBehavior,
    );
  }

  factory ValidationApiException.fromApiException(ApiException error) {
    return ValidationApiException(
      message: error.message,
      statusCode: error.statusCode,
      code: error.code,
      details: error.details,
      data: error.data,
      validationErrors: error.validationErrors,
      cause: error.cause,
      isFallbackMessage: error.isFallbackMessage,
      correlationId: error.correlationId,
      isUnexpectedFailure: error.isUnexpectedFailure,
    );
  }
}

class UnauthorizedApiException extends ApiException {
  const UnauthorizedApiException({
    required super.message,
    super.statusCode,
    super.code,
    super.details,
    super.data,
    super.validationErrors,
    super.cause,
    super.isFallbackMessage,
    super.correlationId,
    super.isUnexpectedFailure,
  });

  factory UnauthorizedApiException.fromApiException(ApiException error) {
    return UnauthorizedApiException(
      message: error.message,
      statusCode: error.statusCode,
      code: error.code,
      details: error.details,
      data: error.data,
      validationErrors: error.validationErrors,
      cause: error.cause,
      isFallbackMessage: error.isFallbackMessage,
      correlationId: error.correlationId,
      isUnexpectedFailure: error.isUnexpectedFailure,
    );
  }
}

class ForbiddenApiException extends ApiException {
  const ForbiddenApiException({
    required super.message,
    super.statusCode,
    super.code,
    super.details,
    super.data,
    super.validationErrors,
    super.cause,
    super.isFallbackMessage,
    super.correlationId,
    super.isUnexpectedFailure,
  });

  factory ForbiddenApiException.fromApiException(ApiException error) {
    return ForbiddenApiException(
      message: error.message,
      statusCode: error.statusCode,
      code: error.code,
      details: error.details,
      data: error.data,
      validationErrors: error.validationErrors,
      cause: error.cause,
      isFallbackMessage: error.isFallbackMessage,
      correlationId: error.correlationId,
      isUnexpectedFailure: error.isUnexpectedFailure,
    );
  }
}

class NotFoundApiException extends ApiException {
  const NotFoundApiException({
    required super.message,
    super.statusCode,
    super.code,
    super.details,
    super.data,
    super.validationErrors,
    super.cause,
    super.isFallbackMessage,
    super.correlationId,
    super.isUnexpectedFailure,
  });

  factory NotFoundApiException.fromApiException(ApiException error) {
    return NotFoundApiException(
      message: error.message,
      statusCode: error.statusCode,
      code: error.code,
      details: error.details,
      data: error.data,
      validationErrors: error.validationErrors,
      cause: error.cause,
      isFallbackMessage: error.isFallbackMessage,
      correlationId: error.correlationId,
      isUnexpectedFailure: error.isUnexpectedFailure,
    );
  }
}

class UserFriendlyApiException extends ApiException {
  const UserFriendlyApiException({
    required super.message,
    super.statusCode,
    super.code,
    super.details,
    super.data,
    super.validationErrors,
    super.cause,
    super.isFallbackMessage,
    super.correlationId,
    super.isUnexpectedFailure,
  });

  factory UserFriendlyApiException.fromApiException(ApiException error) {
    return UserFriendlyApiException(
      message: error.message,
      statusCode: error.statusCode,
      code: error.code,
      details: error.details,
      data: error.data,
      validationErrors: error.validationErrors,
      cause: error.cause,
      isFallbackMessage: error.isFallbackMessage,
      correlationId: error.correlationId,
      isUnexpectedFailure: error.isUnexpectedFailure,
    );
  }
}

class NotImplementedApiException extends ApiException {
  const NotImplementedApiException({
    required super.message,
    super.statusCode,
    super.code,
    super.details,
    super.data,
    super.validationErrors,
    super.cause,
    super.isFallbackMessage,
    super.correlationId,
    super.isUnexpectedFailure,
  });

  factory NotImplementedApiException.fromApiException(ApiException error) {
    return NotImplementedApiException(
      message: error.message,
      statusCode: error.statusCode,
      code: error.code,
      details: error.details,
      data: error.data,
      validationErrors: error.validationErrors,
      cause: error.cause,
      isFallbackMessage: error.isFallbackMessage,
      correlationId: error.correlationId,
      isUnexpectedFailure: true,
    );
  }
}

class ServerApiException extends ApiException {
  const ServerApiException({
    required super.message,
    super.statusCode,
    super.code,
    super.details,
    super.data,
    super.validationErrors,
    super.cause,
    super.isFallbackMessage,
    super.correlationId,
    super.isUnexpectedFailure,
  });

  factory ServerApiException.fromApiException(ApiException error) {
    return ServerApiException(
      message: error.message,
      statusCode: error.statusCode,
      code: error.code,
      details: error.details,
      data: error.data,
      validationErrors: error.validationErrors,
      cause: error.cause,
      isFallbackMessage: error.isFallbackMessage,
      correlationId: error.correlationId,
      isUnexpectedFailure: true,
    );
  }
}

class UnknownApiException extends ApiException {
  const UnknownApiException({
    required super.message,
    super.statusCode,
    super.code,
    super.details,
    super.data,
    super.validationErrors,
    super.cause,
    super.isFallbackMessage,
    super.correlationId,
    super.isUnexpectedFailure,
  });

  factory UnknownApiException.fromApiException(ApiException error) {
    return UnknownApiException(
      message: error.message,
      statusCode: error.statusCode,
      code: error.code,
      details: error.details,
      data: error.data,
      validationErrors: error.validationErrors,
      cause: error.cause,
      isFallbackMessage: error.isFallbackMessage,
      correlationId: error.correlationId,
      isUnexpectedFailure: true,
    );
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
    super.isFallbackMessage,
    super.correlationId,
    super.isUnexpectedFailure,
  });

  factory AbpApiException.fromAbpPayload({
    required AbpErrorPayload payload,
    required int? statusCode,
    required Object? cause,
    String? correlationId,
    String badResponseFallbackMessage =
        ApiException.defaultBadResponseFallbackMessage,
  }) {
    final String normalizedFallbackMessage =
        badResponseFallbackMessage.trim().isNotEmpty
        ? badResponseFallbackMessage.trim()
        : ApiException.defaultBadResponseFallbackMessage;
    final String normalizedMessage = payload.message.trim();
    final bool usedFallbackMessage = normalizedMessage.isEmpty;

    return AbpApiException(
      message: usedFallbackMessage
          ? normalizedFallbackMessage
          : normalizedMessage,
      statusCode: statusCode,
      code: payload.code,
      details: payload.details,
      data: payload.data,
      validationErrors: payload.validationErrors,
      cause: cause,
      isFallbackMessage: usedFallbackMessage,
      correlationId: correlationId,
    );
  }
}

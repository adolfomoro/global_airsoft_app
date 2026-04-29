final class AbpErrorResponse {
  const AbpErrorResponse({required this.error});

  final AbpErrorPayload error;

  factory AbpErrorResponse.fromJson(
    Map<String, dynamic> json, {
    String validationErrorFallbackMessage = 'Validation error',
  }) {
    final Object? errorObject = json['error'];
    if (errorObject is! Map<String, dynamic>) {
      throw const FormatException('ABP error payload is missing "error".');
    }

    return AbpErrorResponse(
      error: AbpErrorPayload.fromJson(
        errorObject,
        validationErrorFallbackMessage: validationErrorFallbackMessage,
      ),
    );
  }
}

final class AbpErrorPayload {
  const AbpErrorPayload({
    required this.code,
    required this.message,
    required this.details,
    required this.data,
    required this.validationErrors,
    required this.additionalData,
  });

  final String? code;
  final String message;
  final String? details;
  final Object? data;
  final List<AbpValidationError> validationErrors;
  final Map<String, dynamic> additionalData;

  factory AbpErrorPayload.fromJson(
    Map<String, dynamic> json, {
    String validationErrorFallbackMessage = 'Validation error',
  }) {
    final Object? rawValidationErrors = json['validationErrors'];
    final List<AbpValidationError> validationErrors;

    if (rawValidationErrors is List) {
      validationErrors = rawValidationErrors
          .whereType<Map<String, dynamic>>()
          .map(
            (Map<String, dynamic> validationError) =>
                AbpValidationError.fromJson(
                  validationError,
                  validationErrorFallbackMessage:
                      validationErrorFallbackMessage,
                ),
          )
          .toList(growable: false);
    } else {
      validationErrors = const <AbpValidationError>[];
    }

    final String message = (json['message'] as String?)?.trim() ?? '';
    final Map<String, dynamic> additionalData = Map<String, dynamic>.from(json)
      ..remove('code')
      ..remove('message')
      ..remove('details')
      ..remove('data')
      ..remove('validationErrors');

    return AbpErrorPayload(
      code: json['code'] as String?,
      message: message,
      details: json['details'] as String?,
      data: json['data'],
      validationErrors: validationErrors,
      additionalData: additionalData,
    );
  }
}

final class AbpValidationError {
  const AbpValidationError({required this.message, required this.members});

  final String message;
  final List<String> members;

  factory AbpValidationError.fromJson(
    Map<String, dynamic> json, {
    String validationErrorFallbackMessage = 'Validation error',
  }) {
    final Object? rawMembers = json['members'];
    final List<String> members;

    if (rawMembers is List) {
      members = rawMembers.whereType<String>().toList(growable: false);
    } else {
      members = const <String>[];
    }

    return AbpValidationError(
      message:
          (json['message'] as String?)?.trim() ??
          validationErrorFallbackMessage,
      members: members,
    );
  }
}

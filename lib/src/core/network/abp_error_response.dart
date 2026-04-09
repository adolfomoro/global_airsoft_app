final class AbpErrorResponse {
  const AbpErrorResponse({required this.error});

  final AbpErrorPayload error;

  factory AbpErrorResponse.fromJson(Map<String, dynamic> json) {
    final Object? errorObject = json['error'];
    if (errorObject is! Map<String, dynamic>) {
      throw const FormatException('ABP error payload is missing "error".');
    }

    return AbpErrorResponse(error: AbpErrorPayload.fromJson(errorObject));
  }
}

final class AbpErrorPayload {
  const AbpErrorPayload({
    required this.code,
    required this.message,
    required this.details,
    required this.validationErrors,
  });

  final String? code;
  final String message;
  final String? details;
  final List<AbpValidationError> validationErrors;

  factory AbpErrorPayload.fromJson(Map<String, dynamic> json) {
    final Object? rawValidationErrors = json['validationErrors'];
    final List<AbpValidationError> validationErrors;

    if (rawValidationErrors is List) {
      validationErrors = rawValidationErrors
          .whereType<Map<String, dynamic>>()
          .map(AbpValidationError.fromJson)
          .toList(growable: false);
    } else {
      validationErrors = const <AbpValidationError>[];
    }

    final String message = (json['message'] as String?)?.trim() ?? 'API error';

    return AbpErrorPayload(
      code: json['code'] as String?,
      message: message,
      details: json['details'] as String?,
      validationErrors: validationErrors,
    );
  }
}

final class AbpValidationError {
  const AbpValidationError({required this.message, required this.members});

  final String message;
  final List<String> members;

  factory AbpValidationError.fromJson(Map<String, dynamic> json) {
    final Object? rawMembers = json['members'];
    final List<String> members;

    if (rawMembers is List) {
      members = rawMembers.whereType<String>().toList(growable: false);
    } else {
      members = const <String>[];
    }

    return AbpValidationError(
      message: (json['message'] as String?)?.trim() ?? 'Validation error',
      members: members,
    );
  }
}

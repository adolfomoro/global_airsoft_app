class AbpApiException implements Exception {
  AbpApiException({
    required this.message,
    this.code,
    this.details,
    this.statusCode,
    this.validationErrors = const <AbpValidationError>[],
    this.responseData,
  });

  final String message;
  final String? code;
  final String? details;
  final int? statusCode;
  final List<AbpValidationError> validationErrors;
  final Map<String, dynamic>? responseData;

  bool get hasValidationErrors => validationErrors.isNotEmpty;

  String get userMessage {
    if (validationErrors.isNotEmpty) {
      return validationErrors.first.message;
    }

    if (message.trim().isNotEmpty) {
      return message.trim();
    }

    if (details != null && details!.trim().isNotEmpty) {
      return details!.trim();
    }

    return 'Erro ao processar a solicitação.';
  }

  @override
  String toString() {
    final status = statusCode != null ? ', statusCode: $statusCode' : '';
    final errorCode = code != null ? ', code: $code' : '';
    return 'AbpApiException(message: $message$errorCode$status)';
  }
}

class AbpValidationError {
  const AbpValidationError({
    required this.message,
    this.members = const <String>[],
  });

  final String message;
  final List<String> members;

  @override
  String toString() {
    if (members.isEmpty) {
      return message;
    }

    return '$message (${members.join(', ')})';
  }
}

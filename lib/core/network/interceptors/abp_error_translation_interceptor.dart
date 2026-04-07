import 'package:dio/dio.dart';

import '../exceptions/abp_api_exception.dart';

class AbpErrorTranslationInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final translated = _tryTranslate(err);
    if (translated == null) {
      handler.next(err);
      return;
    }

    handler.reject(translated);
  }

  DioException? _tryTranslate(DioException err) {
    final response = err.response;
    if (response?.statusCode != 400) {
      return null;
    }

    final statusCode = response?.statusCode;

    final responseData = response?.data;
    if (responseData is! Map) {
      return null;
    }

    final errorData = _asMap(responseData['error']);
    if (errorData == null) {
      return null;
    }

    final translated = _translateError(responseData, errorData, statusCode);
    if (translated == null) {
      return null;
    }

    return DioException(
      requestOptions: err.requestOptions,
      response: response,
      type: DioExceptionType.badResponse,
      error: translated,
      message: translated.userMessage,
    );
  }

  AbpApiException? _translateError(
    Map<dynamic, dynamic> responseData,
    Map<String, dynamic> errorData,
    int? statusCode,
  ) {
    final message = _stringValue(errorData['message']) ?? '';
    final code = _stringValue(errorData['code']);
    final details = _stringValue(errorData['details']);
    final validationErrors = _parseValidationErrors(
      errorData['validationErrors'],
    );

    if (message.isEmpty && details == null && validationErrors.isEmpty) {
      return null;
    }

    return AbpApiException(
      message: message.isEmpty ? 'Erro ao processar a solicitação.' : message,
      code: code,
      details: details,
      statusCode: statusCode,
      validationErrors: validationErrors,
      responseData: Map<String, dynamic>.from(responseData),
    );
  }

  List<AbpValidationError> _parseValidationErrors(Object? rawValue) {
    if (rawValue is! List) {
      return const <AbpValidationError>[];
    }

    final errors = <AbpValidationError>[];
    for (final item in rawValue) {
      final itemMap = _asMap(item);
      if (itemMap == null) {
        continue;
      }

      final message = _stringValue(itemMap['message']);
      if (message == null || message.isEmpty) {
        continue;
      }

      final membersRaw = itemMap['members'];
      final members = <String>[];
      if (membersRaw is List) {
        for (final member in membersRaw) {
          final memberValue = _stringValue(member);
          if (memberValue != null && memberValue.isNotEmpty) {
            members.add(memberValue);
          }
        }
      }

      errors.add(AbpValidationError(message: message, members: members));
    }

    return errors;
  }

  Map<String, dynamic>? _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return value.map((key, dynamic item) => MapEntry(key.toString(), item));
    }

    return null;
  }

  String? _stringValue(Object? value) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}

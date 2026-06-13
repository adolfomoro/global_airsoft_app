import 'package:dio/dio.dart';
import 'package:global_airsoft_app/src/core/network/app_dio_service.dart';
import 'package:global_airsoft_app/src/features/auth/data/constants/auth_api_paths.dart';
import 'package:global_airsoft_app/src/features/auth/domain/models/auth_tokens.dart';

final class AuthTokenRefreshService {
  const AuthTokenRefreshService({required AppDioService dioService})
    : _dioService = dioService;

  final AppDioService _dioService;

  Future<AuthTokens> refreshTokens(String refreshToken) async {
    final Response<dynamic> response = await _dioService.post<dynamic>(
      AuthApiPaths.refreshTokens,
      data: <String, dynamic>{'refreshToken': refreshToken},
    );

    final Map<String, dynamic>? normalized = _normalizeJsonMap(response.data);
    if (normalized == null) {
      throw const FormatException('Token refresh response must be a JSON map.');
    }

    final AuthTokens tokens = AuthTokens.fromJson(normalized);
    if (tokens.jwtToken.trim().isEmpty || tokens.refreshToken.trim().isEmpty) {
      throw const FormatException(
        'Token refresh response returned empty tokens.',
      );
    }

    return tokens;
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

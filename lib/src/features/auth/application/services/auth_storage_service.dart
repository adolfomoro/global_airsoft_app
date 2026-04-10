import 'package:global_airsoft_app/src/core/storage/secure_storage_service.dart';

final class AuthStorageService {
  const AuthStorageService({required SecureStorageService secureStorage})
    : _secureStorage = secureStorage;

  static const String _jwtTokenKey = 'auth_jwt_token';
  static const String _refreshTokenKey = 'auth_refresh_token';

  final SecureStorageService _secureStorage;

  Future<String?> getJwtToken() async {
    try {
      return await _secureStorage.getString(_jwtTokenKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveJwtToken(String token) {
    return _secureStorage.setString(_jwtTokenKey, token);
  }

  Future<String?> getRefreshToken() async {
    try {
      return await _secureStorage.getString(_refreshTokenKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveRefreshToken(String token) {
    return _secureStorage.setString(_refreshTokenKey, token);
  }

  Future<void> clearTokens() async {
    await Future.wait(<Future<void>>[
      _secureStorage.remove(_jwtTokenKey),
      _secureStorage.remove(_refreshTokenKey),
    ]);
  }
}

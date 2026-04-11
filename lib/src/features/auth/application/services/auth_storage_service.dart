import 'dart:convert';
import 'package:global_airsoft_app/src/core/storage/secure_storage_service.dart';
import 'package:global_airsoft_app/src/features/auth/domain/models/auth_profile.dart';
import 'package:global_airsoft_app/src/features/auth/domain/models/auth_tokens.dart';

final class AuthStorageService {
  const AuthStorageService({required SecureStorageService secureStorage})
    : _secureStorage = secureStorage;

  static const String _tokensKey = 'auth_tokens';
  static const String _profileKey = 'auth_profile';

  final SecureStorageService _secureStorage;

  Future<AuthTokens?> getTokens() async {
    try {
      final raw = await _secureStorage.getString(_tokensKey);
      if (raw == null || raw.isEmpty) return null;
      final map = jsonDecode(raw);
      if (map is! Map<String, dynamic>) return null;
      return AuthTokens.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<AuthProfile?> getProfile() async {
    try {
      final raw = await _secureStorage.getString(_profileKey);
      if (raw == null || raw.isEmpty) return null;
      final map = jsonDecode(raw);
      if (map is! Map<String, dynamic>) return null;
      return AuthProfile.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveTokens(AuthTokens tokens) async {
    final payload = jsonEncode(tokens.toJson());
    await _secureStorage.setString(_tokensKey, payload);
  }

  Future<void> saveProfile(AuthProfile profile) async {
    final payload = jsonEncode(profile.toJson());
    await _secureStorage.setString(_profileKey, payload);
  }

  Future<void> clearAll() async {
    await Future.wait([
      _secureStorage.remove(_tokensKey),
      _secureStorage.remove(_profileKey),
    ]);
  }
}

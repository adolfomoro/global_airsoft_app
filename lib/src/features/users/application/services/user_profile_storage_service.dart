import 'dart:convert';

import 'package:global_airsoft_app/src/core/logging/app_logger.dart';
import 'package:global_airsoft_app/src/core/storage/secure_storage_service.dart';
import 'package:global_airsoft_app/src/features/auth/application/services/auth_storage_service.dart';
import 'package:global_airsoft_app/src/features/users/domain/models/user_profile.dart';

final class UserProfileStorageService {
  const UserProfileStorageService({
    required SecureStorageService secureStorage,
    required AuthStorageService authStorageService,
    required AppLogger logger,
  }) : _secureStorage = secureStorage,
       _authStorageService = authStorageService,
       _logger = logger;

  static const String _currentUserProfileKey = 'users.current_user_profile';
  static const String _currentUserProfileUserIdKey =
      'users.current_user_profile_user_id';

  final SecureStorageService _secureStorage;
  final AuthStorageService _authStorageService;
  final AppLogger _logger;

  Future<UserProfile?> getCurrentUserProfile() async {
    try {
      final String? currentAuthenticatedUserId =
          await _resolveCurrentAuthenticatedUserId();
      if (currentAuthenticatedUserId == null ||
          currentAuthenticatedUserId.isEmpty) {
        return null;
      }

      final String? storedUserId = await _secureStorage.getString(
        _currentUserProfileUserIdKey,
      );
      if (storedUserId == null || storedUserId != currentAuthenticatedUserId) {
        return null;
      }

      final String? raw = await _secureStorage.getString(
        _currentUserProfileKey,
      );
      if (raw == null || raw.isEmpty) {
        return null;
      }

      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      return UserProfile(
        id: (decoded['id'] as String? ?? '').trim(),
        username: (decoded['username'] as String? ?? '').trim(),
        fullName: (decoded['fullName'] as String? ?? '').trim(),
        bio: (decoded['bio'] as String? ?? '').trim(),
        mediumProfilePictureUrl:
            (decoded['mediumProfilePictureUrl'] as String? ?? '').trim(),
        largeProfilePictureUrl:
            (decoded['largeProfilePictureUrl'] as String? ?? '').trim(),
      );
    } catch (error, stackTrace) {
      _logger.error(
        'Failed to read stored current user profile.',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<void> saveCurrentUserProfile(UserProfile profile) async {
    final String payload = jsonEncode(<String, String>{
      'id': profile.id,
      'username': profile.username,
      'fullName': profile.fullName,
      'bio': profile.bio,
      'mediumProfilePictureUrl': profile.mediumProfilePictureUrl,
      'largeProfilePictureUrl': profile.largeProfilePictureUrl,
    });

    await Future.wait<void>(<Future<void>>[
      _secureStorage.setString(_currentUserProfileKey, payload),
      _secureStorage.setString(_currentUserProfileUserIdKey, profile.id),
    ]);
  }

  Future<void> clearCurrentUserProfile() async {
    await Future.wait<void>(<Future<void>>[
      _secureStorage.remove(_currentUserProfileKey),
      _secureStorage.remove(_currentUserProfileUserIdKey),
    ]);
  }

  Future<String?> _resolveCurrentAuthenticatedUserId() async {
    final authProfile = await _authStorageService.getProfile();
    final String? userId = authProfile?.userId.trim();
    if (userId == null || userId.isEmpty) {
      return null;
    }

    return userId;
  }
}

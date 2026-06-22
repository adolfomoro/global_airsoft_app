import 'package:global_airsoft_app/src/core/logging/app_logger.dart';
import 'package:global_airsoft_app/src/features/users/application/services/user_profile_offline_photo_storage_service.dart';
import 'package:global_airsoft_app/src/features/users/application/services/user_profile_storage_service.dart';
import 'package:global_airsoft_app/src/features/users/domain/models/user_profile.dart';

final class CurrentUserProfileOfflinePersistenceService {
  CurrentUserProfileOfflinePersistenceService({
    required UserProfileStorageService storageService,
    required UserProfileOfflinePhotoStorageService offlinePhotoStorageService,
    required AppLogger logger,
  }) : _storageService = storageService,
       _offlinePhotoStorageService = offlinePhotoStorageService,
       _logger = logger;

  final UserProfileStorageService _storageService;
  final UserProfileOfflinePhotoStorageService _offlinePhotoStorageService;
  final AppLogger _logger;

  Future<UserProfile?> getCurrentUserProfile() {
    return _storageService.getCurrentUserProfile();
  }

  Future<UserProfile> persistRemoteProfile(UserProfile profile) async {
    final String localProfilePicturePath = await _reconcileRemoteProfilePhoto(
      profile: profile,
    );
    await _storageService.saveCurrentUserProfile(profile);
    return profile.copyWith(localProfilePicturePath: localProfilePicturePath);
  }

  Future<void> clearCurrentUserProfile() {
    return _storageService.clearCurrentUserProfile();
  }

  Future<void> saveCurrentUserProfile(UserProfile profile) {
    return _storageService.saveCurrentUserProfile(profile);
  }

  Future<String> _reconcileRemoteProfilePhoto({
    required UserProfile profile,
  }) async {
    if (profile.id.trim().isEmpty) {
      return '';
    }

    if (!_hasRemoteProfilePhoto(profile)) {
      await _storageService.clearCurrentUserProfilePhoto(userId: profile.id);
      return '';
    }

    try {
      return await _offlinePhotoStorageService.cacheRemoteProfilePhoto(
            userId: profile.id,
            mediumPhotoUrl: profile.mediumProfilePictureUrl,
            largePhotoUrl: profile.largeProfilePictureUrl,
          ) ??
          '';
    } catch (error, stackTrace) {
      _logger.error(
        'Failed to persist remote current user profile assets offline.',
        error: error,
        stackTrace: stackTrace,
      );
      return '';
    }
  }

  bool _hasRemoteProfilePhoto(UserProfile profile) {
    return profile.mediumProfilePictureUrl.trim().isNotEmpty ||
        profile.largeProfilePictureUrl.trim().isNotEmpty;
  }
}

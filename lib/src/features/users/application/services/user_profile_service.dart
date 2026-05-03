import 'dart:io';

import 'package:global_airsoft_app/src/core/logging/app_logger.dart';
import 'package:global_airsoft_app/src/features/users/data/repositories/user_profile_repository/dto/user_profile_output_dto.dart';
import 'package:global_airsoft_app/src/features/users/data/repositories/user_profile_repository/user_profile_repository.dart';
import 'package:global_airsoft_app/src/features/users/domain/models/user_profile.dart';

final class UserProfileService {
  const UserProfileService({
    required UserProfileRepository repository,
    required AppLogger logger,
  }) : _repository = repository,
       _logger = logger;

  final UserProfileRepository _repository;
  final AppLogger _logger;

  Future<UserProfile> getCurrentUserProfile() async {
    final UserProfileOutputDto profile = await _repository
        .getCurrentUserProfile();
    final List<String> profilePictureUrls =
        await Future.wait<String>(<Future<String>>[
          _readProfilePictureUrlSafely(UserProfilePictureSize.medium),
          _readProfilePictureUrlSafely(UserProfilePictureSize.large),
        ]);
    final String mediumPhotoUrl = profilePictureUrls[0];
    final String largePhotoUrl = profilePictureUrls[1];

    return UserProfile(
      id: profile.id,
      username: profile.userName.trim(),
      fullName: profile.fullName?.trim() ?? '',
      bio: profile.bio?.trim() ?? '',
      mediumProfilePictureUrl: mediumPhotoUrl,
      largeProfilePictureUrl: largePhotoUrl.isNotEmpty
          ? largePhotoUrl
          : mediumPhotoUrl,
    );
  }

  Future<void> uploadCurrentUserProfilePicture(File file) {
    return _repository.uploadCurrentUserProfilePicture(file);
  }

  Future<void> deleteCurrentUserProfilePicture() {
    return _repository.deleteCurrentUserProfilePicture();
  }

  Future<String> _readProfilePictureUrlSafely(
    UserProfilePictureSize size,
  ) async {
    try {
      return await _repository.getCurrentUserProfilePictureUrl(size);
    } catch (error, stackTrace) {
      _logger.debug(
        'Current user ${size.name} profile picture URL could not be loaded.',
      );
      _logger.error(
        'Profile picture URL request failed.',
        error: error,
        stackTrace: stackTrace,
      );
      return '';
    }
  }
}

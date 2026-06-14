import 'dart:io';

import 'package:global_airsoft_app/src/features/files/application/services/direct_file_upload_service.dart';
import 'package:global_airsoft_app/src/features/files/application/services/file_content_type_resolver.dart';
import 'package:global_airsoft_app/src/features/files/data/exceptions/direct_file_upload_exception.dart';
import 'package:global_airsoft_app/src/features/files/domain/models/direct_file_upload_authorization.dart';
import 'package:global_airsoft_app/src/features/files/domain/models/direct_file_upload_source.dart';
import 'package:global_airsoft_app/src/features/files/domain/models/direct_file_upload_status.dart';
import 'package:global_airsoft_app/src/features/users/data/repositories/user_profile_repository/dto/user_profile_output_dto.dart';
import 'package:global_airsoft_app/src/features/users/data/repositories/user_profile_repository/dto/user_profile_privacy_settings_output_dto.dart';
import 'package:global_airsoft_app/src/features/users/data/repositories/user_profile_repository/user_profile_repository.dart';
import 'package:global_airsoft_app/src/features/users/domain/models/user_profile.dart';
import 'package:global_airsoft_app/src/features/users/domain/models/user_profile_privacy_settings.dart';
import 'package:path/path.dart' as path;

final class UserProfileService {
  const UserProfileService({
    required UserProfileRepository repository,
    required DirectFileUploadService directFileUploadService,
    required FileContentTypeResolver fileContentTypeResolver,
    int profilePictureUploadStatusMaxAttempts = 10,
    Duration profilePictureUploadStatusPollDelay = const Duration(
      milliseconds: 800,
    ),
  }) : _repository = repository,
       _directFileUploadService = directFileUploadService,
       _fileContentTypeResolver = fileContentTypeResolver,
       _profilePictureUploadStatusMaxAttempts =
           profilePictureUploadStatusMaxAttempts,
       _profilePictureUploadStatusPollDelay =
           profilePictureUploadStatusPollDelay;

  final UserProfileRepository _repository;
  final DirectFileUploadService _directFileUploadService;
  final FileContentTypeResolver _fileContentTypeResolver;
  final int _profilePictureUploadStatusMaxAttempts;
  final Duration _profilePictureUploadStatusPollDelay;

  Future<UserProfile> getCurrentUserProfile() async {
    final UserProfileOutputDto profile = await _repository
        .getCurrentUserProfile();
    final List<String> profilePictureUrls =
        await Future.wait<String>(<Future<String>>[
          _repository.getCurrentUserProfilePictureUrl(
            UserProfilePictureSize.medium,
          ),
          _repository.getCurrentUserProfilePictureUrl(
            UserProfilePictureSize.large,
          ),
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

  Future<void> uploadCurrentUserProfilePicture(File file) async {
    final int sizeBytes = await file.length();
    final String contentType = await _fileContentTypeResolver.resolve(file);
    final String fileName = path.basename(file.path).trim();
    final DirectFileUploadSource source = DirectFileUploadSource(
      fileName: fileName.isEmpty ? 'profile-picture' : fileName,
      contentType: contentType,
      sizeBytes: sizeBytes,
      openRead: file.openRead,
    );
    final DirectFileUploadAuthorization authorization = await _repository
        .initiateCurrentUserProfilePictureUpload(source);

    await _directFileUploadService.uploadSource(
      authorization: authorization,
      source: source,
    );

    final DirectFileUploadStatus completedStatus = await _repository
        .completeCurrentUserProfilePictureUpload(authorization.uploadSessionId);
    if (completedStatus.isComplete) {
      return;
    }

    await _waitForProfilePictureUploadCompletion(authorization.uploadSessionId);
  }

  Future<void> _waitForProfilePictureUploadCompletion(
    String uploadSessionId,
  ) async {
    final int maxAttempts = _profilePictureUploadStatusMaxAttempts <= 0
        ? 1
        : _profilePictureUploadStatusMaxAttempts;

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      if (attempt > 0 && _profilePictureUploadStatusPollDelay > Duration.zero) {
        await Future<void>.delayed(_profilePictureUploadStatusPollDelay);
      }

      final DirectFileUploadStatus status = await _repository
          .getCurrentUserProfilePictureUploadStatus(uploadSessionId);
      if (status.isComplete) {
        return;
      }

      if (status.isTerminal) {
        throw DirectFileUploadException(
          message:
              status.failureReason ??
              'Profile picture upload did not complete successfully.',
        );
      }
    }

    throw const DirectFileUploadException(
      message: 'Timed out waiting for profile picture upload completion.',
    );
  }

  Future<void> deleteCurrentUserProfilePicture() {
    return _repository.deleteCurrentUserProfilePicture();
  }

  Future<void> updateCurrentUserProfile({
    required String fullName,
    required String bio,
  }) async {
    final String normalizedBio = bio.trim();
    await _repository.updateCurrentUserProfile(
      fullName: fullName.trim(),
      bio: normalizedBio.isEmpty ? null : normalizedBio,
    );
  }

  Future<UserProfilePrivacySettings> getCurrentUserPrivacySettings() async {
    final UserProfilePrivacySettingsOutputDto settings = await _repository
        .getCurrentUserPrivacySettings();
    return UserProfilePrivacySettings(
      fullNameVisible: settings.fullNameVisible,
    );
  }

  Future<UserProfilePrivacySettings> updateCurrentUserPrivacySettings(
    UserProfilePrivacySettings settings,
  ) async {
    final UserProfilePrivacySettingsOutputDto updatedSettings =
        await _repository.updateCurrentUserPrivacySettings(
          fullNameVisible: settings.fullNameVisible,
        );
    return UserProfilePrivacySettings(
      fullNameVisible: updatedSettings.fullNameVisible,
    );
  }
}

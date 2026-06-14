import 'package:dio/dio.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localization_service.dart';
import 'package:global_airsoft_app/src/core/network/api_exception.dart';
import 'package:global_airsoft_app/src/core/network/app_dio_service.dart';
import 'package:global_airsoft_app/src/core/network/http_status_code_extensions.dart';
import 'package:global_airsoft_app/src/core/network/message_resolution_policy.dart';
import 'package:global_airsoft_app/src/features/files/data/dto/direct_file_upload_authorization_dto.dart';
import 'package:global_airsoft_app/src/features/files/data/dto/direct_file_upload_status_dto.dart';
import 'package:global_airsoft_app/src/features/files/data/dto/initiate_direct_file_upload_input_dto.dart';
import 'package:global_airsoft_app/src/features/files/domain/models/direct_file_upload_authorization.dart';
import 'package:global_airsoft_app/src/features/files/domain/models/direct_file_upload_source.dart';
import 'package:global_airsoft_app/src/features/files/domain/models/direct_file_upload_status.dart';
import 'package:global_airsoft_app/src/features/users/data/constants/user_profile_api_paths.dart';
import 'package:global_airsoft_app/src/features/users/data/exceptions/user_profile_exception.dart';
import 'package:global_airsoft_app/src/features/users/data/repositories/user_profile_repository/dto/update_my_privacy_settings_input_dto.dart';
import 'package:global_airsoft_app/src/features/users/data/repositories/user_profile_repository/dto/update_user_profile_input_dto.dart';
import 'package:global_airsoft_app/src/features/users/data/repositories/user_profile_repository/dto/user_profile_output_dto.dart';
import 'package:global_airsoft_app/src/features/users/data/repositories/user_profile_repository/dto/user_profile_privacy_settings_output_dto.dart';

enum UserProfilePictureSize { medium, large }

final class UserProfileRepository {
  const UserProfileRepository({
    required AppDioService dioService,
    required AppLocalizationService localizationService,
  }) : _dioService = dioService,
       _localizationService = localizationService;

  final AppDioService _dioService;
  final AppLocalizationService _localizationService;

  Future<String> _profileLoadFailedMessage() {
    return _localizationService.tr(AppLocaleKeys.homeProfileLoadFailedMessage);
  }

  Future<String> _profilePhotoUpdateFailedMessage() {
    return _localizationService.tr(
      AppLocaleKeys.homeProfilePhotoUpdateFailedMessage,
    );
  }

  Future<String> _privacySettingsLoadFailedMessage() {
    return _localizationService.tr(AppLocaleKeys.homePrivacyLoadFailedMessage);
  }

  Future<String> _privacySettingsUpdateFailedMessage() {
    return _localizationService.tr(
      AppLocaleKeys.homePrivacyUpdateFailedMessage,
    );
  }

  Future<String> _profileUpdateFailedMessage() {
    return _localizationService.tr(
      AppLocaleKeys.homeProfileEditUpdateFailedMessage,
    );
  }

  Future<UserProfileOutputDto> getCurrentUserProfile() async {
    try {
      final Response<dynamic> response = await _dioService.get<dynamic>(
        UserProfileApiPaths.currentUserProfile,
      );

      if (response.statusCode.isSuccessStatusCode &&
          response.data is Map<String, dynamic>) {
        return UserProfileOutputDto.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      await _throwLocalizedFailure(
        failureMessageProvider: _profileLoadFailedMessage,
      );
    } on AbpApiException catch (error) {
      await _throwLocalizedUserProfileException(error: error);
    } on ApiException catch (error) {
      await _throwLocalizedUserProfileException(error: error);
    } on DioException {
      await _throwLocalizedFailure(
        failureMessageProvider: _profileLoadFailedMessage,
      );
    }
  }

  Future<String> getCurrentUserProfilePictureUrl(
    UserProfilePictureSize size,
  ) async {
    try {
      final Response<dynamic> response = await _dioService.get<dynamic>(
        switch (size) {
          UserProfilePictureSize.medium =>
            UserProfileApiPaths.currentUserProfilePictureMedium,
          UserProfilePictureSize.large =>
            UserProfileApiPaths.currentUserProfilePictureLarge,
        },
      );

      if (response.statusCode.isSuccessStatusCode) {
        final Object? data = response.data;
        if (data is String) {
          return data.trim();
        }

        if (data == null) {
          return '';
        }
      }

      await _throwLocalizedFailure(
        failureMessageProvider: _profileLoadFailedMessage,
      );
    } on NotFoundApiException {
      return '';
    } on AbpApiException catch (error) {
      await _throwLocalizedUserProfileException(error: error);
    } on ApiException catch (error) {
      await _throwLocalizedUserProfileException(error: error);
    } on DioException {
      await _throwLocalizedFailure(
        failureMessageProvider: _profileLoadFailedMessage,
      );
    }
  }

  Future<UserProfilePrivacySettingsOutputDto>
  getCurrentUserPrivacySettings() async {
    try {
      final Response<dynamic> response = await _dioService.get<dynamic>(
        UserProfileApiPaths.currentUserPrivacySettings,
      );

      if (response.statusCode.isSuccessStatusCode &&
          response.data is Map<String, dynamic>) {
        return UserProfilePrivacySettingsOutputDto.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      await _throwLocalizedFailure(
        failureMessageProvider: _privacySettingsLoadFailedMessage,
      );
    } on AbpApiException catch (error) {
      await _throwLocalizedUserProfileException(
        error: error,
        failureMessageProvider: _privacySettingsLoadFailedMessage,
      );
    } on ApiException catch (error) {
      await _throwLocalizedUserProfileException(
        error: error,
        failureMessageProvider: _privacySettingsLoadFailedMessage,
      );
    } on DioException {
      await _throwLocalizedFailure(
        failureMessageProvider: _privacySettingsLoadFailedMessage,
      );
    }
  }

  Future<UserProfilePrivacySettingsOutputDto> updateCurrentUserPrivacySettings({
    required bool fullNameVisible,
  }) async {
    try {
      final Response<dynamic> response = await _dioService.put<dynamic>(
        UserProfileApiPaths.updateCurrentUserPrivacySettings,
        data: UpdateMyPrivacySettingsInputDto(
          fullNameVisible: fullNameVisible,
        ).toJson(),
      );

      if (response.statusCode.isSuccessStatusCode &&
          response.data is Map<String, dynamic>) {
        return UserProfilePrivacySettingsOutputDto.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      await _throwLocalizedFailure(
        failureMessageProvider: _privacySettingsUpdateFailedMessage,
      );
    } on AbpApiException catch (error) {
      await _throwLocalizedUserProfileException(
        error: error,
        failureMessageProvider: _privacySettingsUpdateFailedMessage,
      );
    } on ApiException catch (error) {
      await _throwLocalizedUserProfileException(
        error: error,
        failureMessageProvider: _privacySettingsUpdateFailedMessage,
      );
    } on DioException {
      await _throwLocalizedFailure(
        failureMessageProvider: _privacySettingsUpdateFailedMessage,
      );
    }
  }

  Future<UserProfileOutputDto> updateCurrentUserProfile({
    required String fullName,
    required String? bio,
  }) async {
    try {
      final Response<dynamic> response = await _dioService.put<dynamic>(
        UserProfileApiPaths.updateCurrentUserProfile,
        data: UpdateUserProfileInputDto(fullName: fullName, bio: bio).toJson(),
      );

      if (response.statusCode.isSuccessStatusCode &&
          response.data is Map<String, dynamic>) {
        return UserProfileOutputDto.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      await _throwLocalizedFailure(
        failureMessageProvider: _profileUpdateFailedMessage,
      );
    } on AbpApiException catch (error) {
      await _throwLocalizedUserProfileException(
        error: error,
        failureMessageProvider: _profileUpdateFailedMessage,
      );
    } on ApiException catch (error) {
      await _throwLocalizedUserProfileException(
        error: error,
        failureMessageProvider: _profileUpdateFailedMessage,
      );
    } on DioException {
      await _throwLocalizedFailure(
        failureMessageProvider: _profileUpdateFailedMessage,
      );
    }
  }

  Future<DirectFileUploadAuthorization> initiateCurrentUserProfilePictureUpload(
    DirectFileUploadSource source, {
    String? expectedChecksum,
    String? checksumAlgorithm,
    String? idempotencyKey,
  }) async {
    try {
      final Response<dynamic> response = await _dioService.post<dynamic>(
        UserProfileApiPaths.currentUserProfilePictureUploadUrl,
        data: InitiateDirectFileUploadInputDto.fromSource(
          source,
          expectedChecksum: expectedChecksum,
          checksumAlgorithm: checksumAlgorithm,
          idempotencyKey: idempotencyKey,
        ).toJson(),
      );

      if (response.statusCode.isSuccessStatusCode &&
          response.data is Map<String, dynamic>) {
        return DirectFileUploadAuthorizationDto.fromJson(
          response.data as Map<String, dynamic>,
        ).toDomain();
      }

      await _throwLocalizedProfilePhotoUpdateFailure();
    } on AbpApiException catch (error) {
      await _throwLocalizedUserProfileException(
        error: error,
        failureMessageProvider: _profilePhotoUpdateFailedMessage,
      );
    } on ApiException catch (error) {
      await _throwLocalizedUserProfileException(
        error: error,
        failureMessageProvider: _profilePhotoUpdateFailedMessage,
      );
    } on DioException {
      await _throwLocalizedProfilePhotoUpdateFailure();
    } on FormatException {
      await _throwLocalizedProfilePhotoUpdateFailure();
    }
  }

  Future<DirectFileUploadStatus> completeCurrentUserProfilePictureUpload(
    String uploadSessionId,
  ) async {
    try {
      final Response<dynamic> response = await _dioService.post<dynamic>(
        UserProfileApiPaths.currentUserProfilePictureUploadComplete(
          uploadSessionId,
        ),
      );

      if (response.statusCode.isSuccessStatusCode &&
          response.data is Map<String, dynamic>) {
        return DirectFileUploadStatusDto.fromJson(
          response.data as Map<String, dynamic>,
        ).toDomain();
      }

      await _throwLocalizedProfilePhotoUpdateFailure();
    } on AbpApiException catch (error) {
      await _throwLocalizedUserProfileException(
        error: error,
        failureMessageProvider: _profilePhotoUpdateFailedMessage,
      );
    } on ApiException catch (error) {
      await _throwLocalizedUserProfileException(
        error: error,
        failureMessageProvider: _profilePhotoUpdateFailedMessage,
      );
    } on DioException {
      await _throwLocalizedProfilePhotoUpdateFailure();
    } on FormatException {
      await _throwLocalizedProfilePhotoUpdateFailure();
    }
  }

  Future<DirectFileUploadStatus> getCurrentUserProfilePictureUploadStatus(
    String uploadSessionId,
  ) async {
    try {
      final Response<dynamic> response = await _dioService.get<dynamic>(
        UserProfileApiPaths.currentUserProfilePictureUploadStatus(
          uploadSessionId,
        ),
      );

      if (response.statusCode.isSuccessStatusCode &&
          response.data is Map<String, dynamic>) {
        return DirectFileUploadStatusDto.fromJson(
          response.data as Map<String, dynamic>,
        ).toDomain();
      }

      await _throwLocalizedProfilePhotoUpdateFailure();
    } on AbpApiException catch (error) {
      await _throwLocalizedUserProfileException(
        error: error,
        failureMessageProvider: _profilePhotoUpdateFailedMessage,
      );
    } on ApiException catch (error) {
      await _throwLocalizedUserProfileException(
        error: error,
        failureMessageProvider: _profilePhotoUpdateFailedMessage,
      );
    } on DioException {
      await _throwLocalizedProfilePhotoUpdateFailure();
    } on FormatException {
      await _throwLocalizedProfilePhotoUpdateFailure();
    }
  }

  Future<void> deleteCurrentUserProfilePicture() async {
    try {
      final Response<dynamic> response = await _dioService.delete<dynamic>(
        UserProfileApiPaths.currentUserProfilePicture,
      );

      if (response.statusCode.isSuccessStatusCode) {
        return;
      }

      await _throwLocalizedProfilePhotoUpdateFailure();
    } on AbpApiException catch (error) {
      await _throwLocalizedUserProfileException(
        error: error,
        failureMessageProvider: _profilePhotoUpdateFailedMessage,
      );
    } on ApiException catch (error) {
      await _throwLocalizedUserProfileException(
        error: error,
        failureMessageProvider: _profilePhotoUpdateFailedMessage,
      );
    } on DioException {
      await _throwLocalizedProfilePhotoUpdateFailure();
    }
  }

  Future<Never> _throwLocalizedUserProfileException({
    required ApiException error,
    Future<String> Function()? failureMessageProvider,
  }) async {
    final String localizedFailureMessage =
        await (failureMessageProvider ?? _profileLoadFailedMessage)();
    final MessageOverrideBehavior overrideBehavior =
        error is ValidationApiException
        ? MessageOverrideBehavior.useAsFallback
        : MessageOverrideBehavior.preferOverride;

    if (error is AbpApiException) {
      throw UserProfileException.fromAbpException(
        error,
        messageOverride: localizedFailureMessage,
        messageOverrideBehavior: overrideBehavior,
      );
    }

    throw UserProfileException.fromApiException(
      error,
      messageOverride: localizedFailureMessage,
      messageOverrideBehavior: overrideBehavior,
    );
  }

  Future<Never> _throwLocalizedFailure({
    required Future<String> Function() failureMessageProvider,
  }) async {
    final String localizedFailureMessage = await failureMessageProvider();

    throw UserProfileException(
      failure: UnknownApiException(message: localizedFailureMessage),
      messageOverride: localizedFailureMessage,
    );
  }

  Future<Never> _throwLocalizedProfilePhotoUpdateFailure() async {
    final String localizedFailureMessage =
        await _profilePhotoUpdateFailedMessage();

    throw UserProfileException(
      failure: UnknownApiException(message: localizedFailureMessage),
      messageOverride: localizedFailureMessage,
    );
  }
}

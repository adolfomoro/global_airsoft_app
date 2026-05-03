import 'dart:io';

import 'package:dio/dio.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localization_service.dart';
import 'package:global_airsoft_app/src/core/network/api_exception.dart';
import 'package:global_airsoft_app/src/core/network/app_dio_service.dart';
import 'package:global_airsoft_app/src/core/network/http_status_code_extensions.dart';
import 'package:global_airsoft_app/src/core/network/message_resolution_policy.dart';
import 'package:global_airsoft_app/src/core/network/multipart_upload_util.dart';
import 'package:global_airsoft_app/src/features/users/data/constants/user_profile_api_paths.dart';
import 'package:global_airsoft_app/src/features/users/data/exceptions/user_profile_exception.dart';
import 'package:global_airsoft_app/src/features/users/data/repositories/user_profile_repository/dto/user_profile_output_dto.dart';

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

      await _throwLocalizedFailure();
    } on AbpApiException catch (error) {
      await _throwLocalizedUserProfileException(error: error);
    } on ApiException catch (error) {
      await _throwLocalizedUserProfileException(error: error);
    } on DioException {
      await _throwLocalizedFailure();
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

      await _throwLocalizedFailure();
    } on NotFoundApiException {
      return '';
    } on AbpApiException catch (error) {
      await _throwLocalizedUserProfileException(error: error);
    } on ApiException catch (error) {
      await _throwLocalizedUserProfileException(error: error);
    } on DioException {
      await _throwLocalizedFailure();
    }
  }

  Future<void> uploadCurrentUserProfilePicture(File file) async {
    try {
      final MultipartFile multipartFile =
          await MultipartUploadUtil.createFromFile(file);
      final FormData data = MultipartUploadUtil.createFormData(
        <String, dynamic>{'File': multipartFile},
      );

      final Response<dynamic> response = await _dioService.post<dynamic>(
        UserProfileApiPaths.currentUserProfilePicture,
        data: data,
        options: Options(contentType: 'multipart/form-data'),
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

  Future<Never> _throwLocalizedFailure() async {
    final String localizedFailureMessage = await _profileLoadFailedMessage();

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

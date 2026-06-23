import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/core/forms/forms.dart' as app_forms;
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_providers.dart';
import 'package:global_airsoft_app/src/core/localization/app_localization_service.dart';
import 'package:global_airsoft_app/src/core/logging/app_logger.dart';
import 'package:global_airsoft_app/src/core/media/profile_photo.dart';
import 'package:global_airsoft_app/src/core/network/multipart_upload_util.dart';
import 'package:global_airsoft_app/src/core/validation/backend_validation_error_mapper.dart';
import 'package:global_airsoft_app/src/features/auth/application/services/auth_service.dart';
import 'package:global_airsoft_app/src/features/auth/data/exceptions/authentication_exception.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/dto/external_sign_up_confirm_input_dto.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/dto/google_sign_up_confirm_input_dto.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/state/google_account_setup_form_state.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/validators/google_account_setup_form_validator.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/widgets/username_availability_field.dart';
import 'package:global_airsoft_app/src/features/users/application/providers/current_user_profile_providers.dart';

final googleAccountSetupFormControllerProvider =
    NotifierProvider.autoDispose<
      GoogleAccountSetupFormController,
      GoogleAccountSetupFormState
    >(GoogleAccountSetupFormController.new);

final class GoogleAccountSetupFormController
    extends Notifier<GoogleAccountSetupFormState> {
  static const BackendValidationErrorMapper _validationErrorMapper =
      BackendValidationErrorMapper();
  static const GoogleAccountSetupFormValidator _validator =
      GoogleAccountSetupFormValidator();
  static const String _initialStringValue = '';

  @override
  GoogleAccountSetupFormState build() {
    return const GoogleAccountSetupFormState();
  }

  AppLocalizationService get _localizationService {
    return ref.read(appLocalizationServiceProvider);
  }

  void initialize({
    required String challengeToken,
    required String profilePictureUrl,
    required String profileName,
  }) {
    if (state.isInitialized) {
      return;
    }

    final String suggestedUsername = _suggestUsernameFromProfileName(
      profileName,
    );
    final String trimmedProfilePictureUrl = profilePictureUrl.trim();

    state = state.copyWith(
      challengeToken: challengeToken,
      username: state.username.copyWith(
        value: suggestedUsername,
        isDirty: suggestedUsername != _initialStringValue,
      ),
      profilePhoto: trimmedProfilePictureUrl.isEmpty
          ? const ProfilePhoto.empty()
          : ProfilePhoto.network(trimmedProfilePictureUrl),
      isInitialized: true,
    );
  }

  void updateUsername(String value) {
    state = state.copyWith(
      username: _fieldChanged(state.username, value),
      generalError: null,
    );
  }

  void updateUsernameAvailabilityStatus(UsernameAvailabilityStatus status) {
    if (state.usernameAvailabilityStatus == status) {
      return;
    }

    state = state.copyWith(usernameAvailabilityStatus: status);
  }

  void updateProfilePhoto(ProfilePhoto profilePhoto) {
    if (state.profilePhoto == profilePhoto) {
      return;
    }

    state = state.copyWith(profilePhoto: profilePhoto);
  }

  void markSubmitted() {
    if (state.wasSubmitted) {
      return;
    }

    state = state.copyWith(wasSubmitted: true);
  }

  Future<void> submit() async {
    if (state.isSubmitting) {
      return;
    }

    final AppLocalizationService localizationService = _localizationService;
    final GoogleAccountSetupValidationResult validationResult = _validator
        .validate(username: state.username.value);

    state = state.copyWith(
      username: await _fieldValidated(
        state.username,
        validationResult.usernameIssue,
        localizationService,
      ),
      generalError: null,
      wasSubmitted: true,
    );

    if (!validationResult.isValid ||
        state.usernameAvailabilityStatus.blocksSubmission) {
      return;
    }

    state = state.copyWith(isSubmitting: true, generalError: null);

    try {
      final MultipartFile? profilePictureFile =
          await _resolveProfilePictureFile(state.profilePhoto);

      final GoogleSignUpConfirmInputDto input = GoogleSignUpConfirmInputDto(
        challengeToken: state.challengeToken,
        username: state.trimmedUsername,
        profilePictureFile: profilePictureFile,
      );

      final AuthService authService = ref.read(authServiceProvider);
      await authService.signUpWithGoogle(input);
      await _completeAuthenticatedSession();
    } on AuthenticationException catch (error) {
      await _applyAuthenticationFailure(error);
    } catch (error, stackTrace) {
      AppLogger.instance.error(
        'Unexpected Google sign-up failure.',
        error: error,
        stackTrace: stackTrace,
      );

      state = state.copyWith(
        generalError: await localizationService.tr(
          AppLocaleKeys.authSignUpFailed,
        ),
      );
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }

  app_forms.FormFieldState<String> _fieldChanged(
    app_forms.FormFieldState<String> field,
    String value,
  ) {
    return field.copyWith(
      value: value,
      error: null,
      isTouched: true,
      isDirty: value != _initialStringValue,
    );
  }

  Future<app_forms.FormFieldState<String>> _fieldValidated(
    app_forms.FormFieldState<String> field,
    GoogleAccountSetupValidationIssue? issue,
    AppLocalizationService localizationService,
  ) async {
    final String? error = issue == null
        ? null
        : await issue.resolve(localizationService);

    return field.copyWith(error: error, isTouched: true);
  }

  Future<void> _applyAuthenticationFailure(
    AuthenticationException error,
  ) async {
    final ValidationMappingResult mappedErrors = _validationErrorMapper.map(
      exception: error.failure,
      targetFields: const <String>{ExternalSignUpConfirmInputDto.usernameField},
    );

    final String? message =
        error.message ?? _firstMeaningfulGlobalError(mappedErrors);

    state = state.copyWith(
      username: _applyBackendFieldError(
        state.username,
        mappedErrors.fieldErrors[ExternalSignUpConfirmInputDto.usernameField],
      ),
      generalError: message,
      wasSubmitted: true,
    );
  }

  app_forms.FormFieldState<String> _applyBackendFieldError(
    app_forms.FormFieldState<String> field,
    String? error,
  ) {
    if (error == null) {
      return field;
    }

    return field.copyWith(error: error, isTouched: true);
  }

  Future<MultipartFile?> _resolveProfilePictureFile(
    ProfilePhoto profilePhoto,
  ) async {
    if (profilePhoto.isLocal) {
      final File localFile = profilePhoto.localFile!;
      return MultipartUploadUtil.createFromFile(localFile);
    }

    if (profilePhoto.isNetwork) {
      final String networkUrl = profilePhoto.networkUrl!;
      return MultipartUploadUtil.createFromUrl(networkUrl);
    }

    return null;
  }

  Future<void> _completeAuthenticatedSession() async {
    await ref
        .read(appLocaleControllerProvider.notifier)
        .forceApplyServerLocaleIfPending();
    ref.read(currentUserProfileRefreshRequestProvider.notifier).clear();
    ref.invalidate(currentUserProfileRefreshRequestProvider);
    ref.invalidate(currentUserProfileProvider);
    ref.read(isAuthenticatedProvider.notifier).setAuthenticated();
  }

  String? _firstMeaningfulGlobalError(ValidationMappingResult mappedErrors) {
    for (final String value in mappedErrors.globalErrors) {
      final String trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }

    return null;
  }

  static String _suggestUsernameFromProfileName(String profileName) {
    return profileName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '.')
        .replaceAll(RegExp(r'[^a-z0-9_.]'), '')
        .replaceAll(RegExp(r'[_.]{2,}'), '.')
        .replaceAll(RegExp(r'^[_.]+|[_.]+$'), '');
  }
}

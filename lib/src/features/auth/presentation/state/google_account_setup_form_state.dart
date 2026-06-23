import 'package:flutter/foundation.dart';
import 'package:global_airsoft_app/src/core/forms/forms.dart';
import 'package:global_airsoft_app/src/core/media/profile_photo.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/validators/google_account_setup_form_validator.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/widgets/username_availability_field.dart';

const Object _googleAccountSetupFormStateNoChange = Object();

@immutable
final class GoogleAccountSetupFormState {
  const GoogleAccountSetupFormState({
    this.challengeToken = '',
    this.username = const FormFieldState<String>(value: ''),
    this.profilePhoto = const ProfilePhoto.empty(),
    this.usernameAvailabilityStatus = UsernameAvailabilityStatus.idle,
    this.isSubmitting = false,
    this.generalError,
    this.wasSubmitted = false,
    this.isInitialized = false,
  });

  final String challengeToken;
  final FormFieldState<String> username;
  final ProfilePhoto profilePhoto;
  final UsernameAvailabilityStatus usernameAvailabilityStatus;
  final bool isSubmitting;
  final String? generalError;
  final bool wasSubmitted;
  final bool isInitialized;

  String get trimmedUsername => username.value.trim().toLowerCase();

  bool get hasGeneralError => generalError != null && generalError!.isNotEmpty;

  bool get isValid =>
      GoogleAccountSetupFormValidator.isUsernameValid(trimmedUsername);

  bool get canSubmit =>
      isValid && !isSubmitting && !usernameAvailabilityStatus.blocksSubmission;

  GoogleAccountSetupFormState copyWith({
    String? challengeToken,
    FormFieldState<String>? username,
    ProfilePhoto? profilePhoto,
    UsernameAvailabilityStatus? usernameAvailabilityStatus,
    bool? isSubmitting,
    Object? generalError = _googleAccountSetupFormStateNoChange,
    bool? wasSubmitted,
    bool? isInitialized,
  }) {
    return GoogleAccountSetupFormState(
      challengeToken: challengeToken ?? this.challengeToken,
      username: username ?? this.username,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      usernameAvailabilityStatus:
          usernameAvailabilityStatus ?? this.usernameAvailabilityStatus,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      generalError:
          identical(generalError, _googleAccountSetupFormStateNoChange)
          ? this.generalError
          : generalError as String?,
      wasSubmitted: wasSubmitted ?? this.wasSubmitted,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

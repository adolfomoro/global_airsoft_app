import 'package:flutter/foundation.dart';
import 'package:global_airsoft_app/src/core/forms/forms.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/validators/sign_up_form_validator.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/widgets/username_availability_field.dart';

const Object _signUpFormStateNoChange = Object();

@immutable
final class SignUpFormState {
  const SignUpFormState({
    this.fullName = const FormFieldState<String>(value: ''),
    this.username = const FormFieldState<String>(value: ''),
    this.email = const FormFieldState<String>(value: ''),
    this.password = const FormFieldState<String>(value: ''),
    this.confirmPassword = const FormFieldState<String>(value: ''),
    this.usernameAvailabilityStatus = UsernameAvailabilityStatus.idle,
    this.isSubmitting = false,
    this.generalError,
    this.wasSubmitted = false,
  });

  final FormFieldState<String> fullName;
  final FormFieldState<String> username;
  final FormFieldState<String> email;
  final FormFieldState<String> password;
  final FormFieldState<String> confirmPassword;
  final UsernameAvailabilityStatus usernameAvailabilityStatus;
  final bool isSubmitting;
  final String? generalError;
  final bool wasSubmitted;

  String get trimmedFullName => fullName.value.trim();

  String get trimmedUsername => username.value.trim();

  String get trimmedEmail => email.value.trim();

  bool get hasGeneralError => generalError != null && generalError!.isNotEmpty;

  bool get hasErrors =>
      hasGeneralError ||
      fullName.hasError ||
      username.hasError ||
      email.hasError ||
      password.hasError ||
      confirmPassword.hasError;

  bool get passwordsMatch => SignUpFormValidator.doPasswordsMatch(
    password: password.value,
    confirmPassword: confirmPassword.value,
  );

  bool get isValid =>
      SignUpFormValidator.isFullNameValid(trimmedFullName) &&
      SignUpFormValidator.isUsernameValid(trimmedUsername) &&
      SignUpFormValidator.isEmailValid(trimmedEmail) &&
      SignUpFormValidator.isPasswordValid(password.value) &&
      SignUpFormValidator.isConfirmPasswordFilled(confirmPassword.value) &&
      passwordsMatch;

  bool get canSubmit =>
      isValid && !isSubmitting && !usernameAvailabilityStatus.blocksSubmission;

  SignUpFormState copyWith({
    FormFieldState<String>? fullName,
    FormFieldState<String>? username,
    FormFieldState<String>? email,
    FormFieldState<String>? password,
    FormFieldState<String>? confirmPassword,
    UsernameAvailabilityStatus? usernameAvailabilityStatus,
    bool? isSubmitting,
    Object? generalError = _signUpFormStateNoChange,
    bool? wasSubmitted,
  }) {
    return SignUpFormState(
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
        usernameAvailabilityStatus:
          usernameAvailabilityStatus ?? this.usernameAvailabilityStatus,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      generalError: identical(generalError, _signUpFormStateNoChange)
          ? this.generalError
          : generalError as String?,
      wasSubmitted: wasSubmitted ?? this.wasSubmitted,
    );
  }
}

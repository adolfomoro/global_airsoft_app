import 'package:flutter/foundation.dart';
import 'package:global_airsoft_app/src/core/forms/forms.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/validators/login_form_validator.dart';

const Object _loginFormStateNoChange = Object();

enum LoginSubmissionType { credentials, google }

@immutable
final class LoginFormState {
  const LoginFormState({
    this.login = const FormFieldState<String>(value: ''),
    this.password = const FormFieldState<String>(value: ''),
    this.activeSubmission,
    this.generalError,
    this.wasSubmitted = false,
  });

  final FormFieldState<String> login;
  final FormFieldState<String> password;
  final LoginSubmissionType? activeSubmission;
  final String? generalError;
  final bool wasSubmitted;

  String get trimmedLogin => login.value.trim();

  bool get isSubmitting => activeSubmission != null;

  bool get isCredentialsSubmitting =>
      activeSubmission == LoginSubmissionType.credentials;

  bool get isGoogleSubmitting => activeSubmission == LoginSubmissionType.google;

  bool get hasGeneralError => generalError != null && generalError!.isNotEmpty;

  bool get isValid =>
      LoginFormValidator.isLoginValid(trimmedLogin) &&
      LoginFormValidator.isPasswordValid(password.value);

  bool get canSubmitCredentials => isValid && !isSubmitting;

  bool get canSubmitGoogle => !isSubmitting;

  LoginFormState copyWith({
    FormFieldState<String>? login,
    FormFieldState<String>? password,
    Object? activeSubmission = _loginFormStateNoChange,
    Object? generalError = _loginFormStateNoChange,
    bool? wasSubmitted,
  }) {
    return LoginFormState(
      login: login ?? this.login,
      password: password ?? this.password,
      activeSubmission: identical(activeSubmission, _loginFormStateNoChange)
          ? this.activeSubmission
          : activeSubmission as LoginSubmissionType?,
      generalError: identical(generalError, _loginFormStateNoChange)
          ? this.generalError
          : generalError as String?,
      wasSubmitted: wasSubmitted ?? this.wasSubmitted,
    );
  }
}

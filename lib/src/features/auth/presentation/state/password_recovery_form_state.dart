import 'package:flutter/foundation.dart';
import 'package:global_airsoft_app/src/core/forms/forms.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/validators/password_recovery_form_validator.dart';

const Object _passwordRecoveryFormStateNoChange = Object();

@immutable
final class PasswordRecoveryFormState {
  const PasswordRecoveryFormState({
    this.email = const FormFieldState<String>(value: ''),
    this.isSubmitting = false,
    this.generalError,
    this.wasSubmitted = false,
  });

  final FormFieldState<String> email;
  final bool isSubmitting;
  final String? generalError;
  final bool wasSubmitted;

  String get trimmedEmail => email.value.trim();

  bool get hasGeneralError => generalError != null && generalError!.isNotEmpty;

  bool get isValid => PasswordRecoveryFormValidator.isEmailValid(trimmedEmail);

  bool get canSubmit => isValid && !isSubmitting;

  PasswordRecoveryFormState copyWith({
    FormFieldState<String>? email,
    bool? isSubmitting,
    Object? generalError = _passwordRecoveryFormStateNoChange,
    bool? wasSubmitted,
  }) {
    return PasswordRecoveryFormState(
      email: email ?? this.email,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      generalError: identical(generalError, _passwordRecoveryFormStateNoChange)
          ? this.generalError
          : generalError as String?,
      wasSubmitted: wasSubmitted ?? this.wasSubmitted,
    );
  }
}

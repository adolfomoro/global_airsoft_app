import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/core/forms/forms.dart' as app_forms;
import 'package:global_airsoft_app/src/core/validation/full_name_validation.dart';
import 'package:global_airsoft_app/src/features/auth/domain/validation/email_validation.dart';
import 'package:global_airsoft_app/src/features/auth/domain/validation/password_validation_policy.dart';
import 'package:global_airsoft_app/src/features/auth/domain/validation/username_validation.dart';

/// Full name field notifier for sign-up
final class SignUpFullNameFieldNotifier
    extends app_forms.StringFormFieldNotifier {
  @override
  String get initialValue => '';
}

/// Username field notifier for sign-up
final class SignUpUsernameFieldNotifier
    extends app_forms.StringFormFieldNotifier {
  @override
  String get initialValue => '';
}

/// Email field notifier for sign-up
final class SignUpEmailFieldNotifier extends app_forms.StringFormFieldNotifier {
  @override
  String get initialValue => '';
}

/// Password field notifier for sign-up
final class SignUpPasswordFieldNotifier
    extends app_forms.StringFormFieldNotifier {
  @override
  String get initialValue => '';
}

/// Confirm password field notifier for sign-up
final class SignUpConfirmPasswordFieldNotifier
    extends app_forms.StringFormFieldNotifier {
  @override
  String get initialValue => '';
}

/// Sign-up form submission state notifier
final class SignUpFormStateNotifier extends app_forms.FormStateNotifier {}

// ============================================================================
// FIELD PROVIDERS
// ============================================================================

final signUpFullNameFieldProvider =
    NotifierProvider.autoDispose<
      SignUpFullNameFieldNotifier,
      app_forms.FormFieldState<String>
    >(() => SignUpFullNameFieldNotifier());

final signUpUsernameFieldProvider =
    NotifierProvider.autoDispose<
      SignUpUsernameFieldNotifier,
      app_forms.FormFieldState<String>
    >(() => SignUpUsernameFieldNotifier());

final signUpEmailFieldProvider =
    NotifierProvider.autoDispose<
      SignUpEmailFieldNotifier,
      app_forms.FormFieldState<String>
    >(() => SignUpEmailFieldNotifier());

final signUpPasswordFieldProvider =
    NotifierProvider.autoDispose<
      SignUpPasswordFieldNotifier,
      app_forms.FormFieldState<String>
    >(() => SignUpPasswordFieldNotifier());

final signUpConfirmPasswordFieldProvider =
    NotifierProvider.autoDispose<
      SignUpConfirmPasswordFieldNotifier,
      app_forms.FormFieldState<String>
    >(() => SignUpConfirmPasswordFieldNotifier());

final signUpFormStateProvider =
    NotifierProvider.autoDispose<
      SignUpFormStateNotifier,
      app_forms.FormSubmissionState
    >(() => SignUpFormStateNotifier());

// ============================================================================
// FULL NAME SELECTORS
// ============================================================================

final signUpFullNameValueProvider = Provider.autoDispose<String>((ref) {
  final state = ref.watch(signUpFullNameFieldProvider);
  return state.value;
});

final signUpFullNameErrorProvider = Provider.autoDispose<String?>((ref) {
  final state = ref.watch(signUpFullNameFieldProvider);
  return state.error;
});

final signUpFullNameIsValidProvider = Provider.autoDispose<bool>((ref) {
  final value = ref.watch(signUpFullNameValueProvider);
  return FullNameValidation.rules.validate(value) == null;
});

// ============================================================================
// USERNAME SELECTORS
// ============================================================================

final signUpUsernameValueProvider = Provider.autoDispose<String>((ref) {
  final state = ref.watch(signUpUsernameFieldProvider);
  return state.value;
});

final signUpUsernameErrorProvider = Provider.autoDispose<String?>((ref) {
  final state = ref.watch(signUpUsernameFieldProvider);
  return state.error;
});

final signUpUsernameIsValidProvider = Provider.autoDispose<bool>((ref) {
  final value = ref.watch(signUpUsernameValueProvider);
  return UsernameValidation.rules.validate(value) == null;
});

// ============================================================================
// EMAIL SELECTORS
// ============================================================================

final signUpEmailValueProvider = Provider.autoDispose<String>((ref) {
  final state = ref.watch(signUpEmailFieldProvider);
  return state.value;
});

final signUpEmailErrorProvider = Provider.autoDispose<String?>((ref) {
  final state = ref.watch(signUpEmailFieldProvider);
  return state.error;
});

final signUpEmailIsValidProvider = Provider.autoDispose<bool>((ref) {
  final value = ref.watch(signUpEmailValueProvider);
  return EmailValidation.rules.validate(value) == null;
});

// ============================================================================
// PASSWORD SELECTORS
// ============================================================================

final signUpPasswordValueProvider = Provider.autoDispose<String>((ref) {
  final state = ref.watch(signUpPasswordFieldProvider);
  return state.value;
});

final signUpPasswordErrorProvider = Provider.autoDispose<String?>((ref) {
  final state = ref.watch(signUpPasswordFieldProvider);
  return state.error;
});

final signUpPasswordIsValidProvider = Provider.autoDispose<bool>((ref) {
  final value = ref.watch(signUpPasswordValueProvider);
  return PasswordValidationPolicy.rules.validate(value) == null;
});

// ============================================================================
// CONFIRM PASSWORD SELECTORS
// ============================================================================

final signUpConfirmPasswordValueProvider = Provider.autoDispose<String>((ref) {
  final state = ref.watch(signUpConfirmPasswordFieldProvider);
  return state.value;
});

final signUpConfirmPasswordErrorProvider = Provider.autoDispose<String?>((ref) {
  final state = ref.watch(signUpConfirmPasswordFieldProvider);
  return state.error;
});

final signUpConfirmPasswordIsValidProvider = Provider.autoDispose<bool>((ref) {
  final value = ref.watch(signUpConfirmPasswordValueProvider);
  return value.trim().isNotEmpty;
});

// ============================================================================
// PASSWORD MATCHING VALIDATOR
// ============================================================================

final signUpPasswordsMatchProvider = Provider.autoDispose<bool>((ref) {
  final password = ref.watch(signUpPasswordValueProvider);
  final confirmPassword = ref.watch(signUpConfirmPasswordValueProvider);
  return password.isNotEmpty && password == confirmPassword;
});

// ============================================================================
// FORM WIDE SELECTORS
// ============================================================================

final signUpIsSubmittingProvider = Provider.autoDispose<bool>((ref) {
  final state = ref.watch(signUpFormStateProvider);
  return state.isSubmitting;
});

final signUpFormErrorProvider = Provider.autoDispose<String?>((ref) {
  final state = ref.watch(signUpFormStateProvider);
  return state.generalError;
});

// ============================================================================
// FORM VALIDATION STATE
// ============================================================================

final signUpFormIsValidProvider = Provider.autoDispose<bool>((ref) {
  final fullNameValid = ref.watch(signUpFullNameIsValidProvider);
  final usernameValid = ref.watch(signUpUsernameIsValidProvider);
  final emailValid = ref.watch(signUpEmailIsValidProvider);
  final passwordValid = ref.watch(signUpPasswordIsValidProvider);
  final confirmPasswordValid = ref.watch(signUpConfirmPasswordIsValidProvider);
  final passwordsMatch = ref.watch(signUpPasswordsMatchProvider);

  return fullNameValid &&
      usernameValid &&
      emailValid &&
      passwordValid &&
      confirmPasswordValid &&
      passwordsMatch;
});

final signUpSubmitEnabledProvider = Provider.autoDispose<bool>((ref) {
  final isValid = ref.watch(signUpFormIsValidProvider);
  final isSubmitting = ref.watch(signUpIsSubmittingProvider);
  return isValid && !isSubmitting;
});

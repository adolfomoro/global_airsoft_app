import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/core/forms/forms.dart' as app_forms;

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
    NotifierProvider<SignUpFullNameFieldNotifier, app_forms.FormFieldState<String>>(
  () => SignUpFullNameFieldNotifier(),
);

final signUpUsernameFieldProvider =
    NotifierProvider<SignUpUsernameFieldNotifier, app_forms.FormFieldState<String>>(
  () => SignUpUsernameFieldNotifier(),
);

final signUpEmailFieldProvider =
    NotifierProvider<SignUpEmailFieldNotifier, app_forms.FormFieldState<String>>(
  () => SignUpEmailFieldNotifier(),
);

final signUpPasswordFieldProvider =
    NotifierProvider<SignUpPasswordFieldNotifier, app_forms.FormFieldState<String>>(
  () => SignUpPasswordFieldNotifier(),
);

final signUpConfirmPasswordFieldProvider = NotifierProvider<
    SignUpConfirmPasswordFieldNotifier,
    app_forms.FormFieldState<String>>(
  () => SignUpConfirmPasswordFieldNotifier(),
);

final signUpFormStateProvider =
    NotifierProvider<SignUpFormStateNotifier, app_forms.FormSubmissionState>(
  () => SignUpFormStateNotifier(),
);

// ============================================================================
// FULL NAME SELECTORS
// ============================================================================

final signUpFullNameValueProvider = Provider<String>((ref) {
  final state = ref.watch(signUpFullNameFieldProvider);
  return state.value;
});

final signUpFullNameErrorProvider = Provider<String?>((ref) {
  final state = ref.watch(signUpFullNameFieldProvider);
  return state.error;
});

final signUpFullNameIsValidProvider = Provider<bool>((ref) {
  final state = ref.watch(signUpFullNameFieldProvider);
  return state.isValid;
});

// ============================================================================
// USERNAME SELECTORS
// ============================================================================

final signUpUsernameValueProvider = Provider<String>((ref) {
  final state = ref.watch(signUpUsernameFieldProvider);
  return state.value;
});

final signUpUsernameErrorProvider = Provider<String?>((ref) {
  final state = ref.watch(signUpUsernameFieldProvider);
  return state.error;
});

final signUpUsernameIsValidProvider = Provider<bool>((ref) {
  final state = ref.watch(signUpUsernameFieldProvider);
  return state.isValid;
});

// ============================================================================
// EMAIL SELECTORS
// ============================================================================

final signUpEmailValueProvider = Provider<String>((ref) {
  final state = ref.watch(signUpEmailFieldProvider);
  return state.value;
});

final signUpEmailErrorProvider = Provider<String?>((ref) {
  final state = ref.watch(signUpEmailFieldProvider);
  return state.error;
});

final signUpEmailIsValidProvider = Provider<bool>((ref) {
  final state = ref.watch(signUpEmailFieldProvider);
  return state.isValid;
});

// ============================================================================
// PASSWORD SELECTORS
// ============================================================================

final signUpPasswordValueProvider = Provider<String>((ref) {
  final state = ref.watch(signUpPasswordFieldProvider);
  return state.value;
});

final signUpPasswordErrorProvider = Provider<String?>((ref) {
  final state = ref.watch(signUpPasswordFieldProvider);
  return state.error;
});

final signUpPasswordIsValidProvider = Provider<bool>((ref) {
  final state = ref.watch(signUpPasswordFieldProvider);
  return state.isValid;
});

// ============================================================================
// CONFIRM PASSWORD SELECTORS
// ============================================================================

final signUpConfirmPasswordValueProvider = Provider<String>((ref) {
  final state = ref.watch(signUpConfirmPasswordFieldProvider);
  return state.value;
});

final signUpConfirmPasswordErrorProvider = Provider<String?>((ref) {
  final state = ref.watch(signUpConfirmPasswordFieldProvider);
  return state.error;
});

final signUpConfirmPasswordIsValidProvider = Provider<bool>((ref) {
  final state = ref.watch(signUpConfirmPasswordFieldProvider);
  return state.isValid;
});

// ============================================================================
// PASSWORD MATCHING VALIDATOR
// ============================================================================

final signUpPasswordsMatchProvider = Provider<bool>((ref) {
  final password = ref.watch(signUpPasswordValueProvider);
  final confirmPassword = ref.watch(signUpConfirmPasswordValueProvider);
  return password.isNotEmpty && password == confirmPassword;
});

// ============================================================================
// FORM WIDE SELECTORS
// ============================================================================

final signUpIsSubmittingProvider = Provider<bool>((ref) {
  final state = ref.watch(signUpFormStateProvider);
  return state.isSubmitting;
});

final signUpFormErrorProvider = Provider<String?>((ref) {
  final state = ref.watch(signUpFormStateProvider);
  return state.generalError;
});

// ============================================================================
// FORM VALIDATION STATE
// ============================================================================

final signUpFormIsValidProvider = Provider<bool>((ref) {
  final fullNameValid = ref.watch(signUpFullNameIsValidProvider);
  final usernameValid = ref.watch(signUpUsernameIsValidProvider);
  final emailValid = ref.watch(signUpEmailIsValidProvider);
  final passwordValid = ref.watch(signUpPasswordIsValidProvider);
  final passwordsMatch = ref.watch(signUpPasswordsMatchProvider);

  return fullNameValid &&
      usernameValid &&
      emailValid &&
      passwordValid &&
      passwordsMatch;
});

final signUpSubmitEnabledProvider = Provider<bool>((ref) {
  final isValid = ref.watch(signUpFormIsValidProvider);
  final isSubmitting = ref.watch(signUpIsSubmittingProvider);
  return isValid && !isSubmitting;
});

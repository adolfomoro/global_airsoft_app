import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/core/forms/forms.dart'
    as app_forms;

/// Login field specific notifier
/// Extends StringFormFieldNotifier for reusable String validation
final class LoginFieldNotifier extends app_forms.StringFormFieldNotifier {
  @override
  String get initialValue => '';
}

/// Password field specific notifier
final class PasswordFieldNotifier extends app_forms.StringFormFieldNotifier {
  @override
  String get initialValue => '';
}

/// Login form submission state notifier
final class LoginFormStateNotifier extends app_forms.FormStateNotifier {}

// ============================================================================
// PROVIDERS - Fine-grained, using .select() for optimal performance
// ============================================================================

/// Provider for login field state
final loginFieldProvider =
    NotifierProvider<LoginFieldNotifier, app_forms.FormFieldState<String>>(
  () => LoginFieldNotifier(),
);

/// Provider for password field state
final passwordFieldProvider =
    NotifierProvider<PasswordFieldNotifier, app_forms.FormFieldState<String>>(
  () => PasswordFieldNotifier(),
);

/// Provider for login form submission state
final loginFormStateProvider =
    NotifierProvider<LoginFormStateNotifier, app_forms.FormSubmissionState>(
  () => LoginFormStateNotifier(),
);

// ============================================================================
// SELECTORS - Granular watches for optimal widget rebuilds
// ============================================================================

/// Selector: only watch login value
final loginValueProvider = Provider<String>((ref) {
  final state = ref.watch(loginFieldProvider);
  return state.value;
});

/// Selector: only watch login error
final loginErrorProvider = Provider<String?>((ref) {
  final state = ref.watch(loginFieldProvider);
  return state.error;
});

/// Selector: only watch login validation state
final loginIsValidProvider = Provider<bool>((ref) {
  final state = ref.watch(loginFieldProvider);
  return state.isValid;
});

/// Selector: only watch password value
final passwordValueProvider = Provider<String>((ref) {
  final state = ref.watch(passwordFieldProvider);
  return state.value;
});

/// Selector: only watch password error
final passwordErrorProvider = Provider<String?>((ref) {
  final state = ref.watch(passwordFieldProvider);
  return state.error;
});

/// Selector: only watch password validation state
final passwordIsValidProvider = Provider<bool>((ref) {
  final state = ref.watch(passwordFieldProvider);
  return state.isValid;
});

/// Selector: only watch form loading state
final loginIsSubmittingProvider = Provider<bool>((ref) {
  final state = ref.watch(loginFormStateProvider);
  return state.isSubmitting;
});

/// Selector: only watch form general error
final loginFormErrorProvider = Provider<String?>((ref) {
  final state = ref.watch(loginFormStateProvider);
  return state.generalError;
});

/// Derived: whether login form is in valid state (both fields)
final loginFormIsValidProvider = Provider<bool>(
  (ref) {
    final loginValid = ref.watch(loginIsValidProvider);
    final passwordValid = ref.watch(passwordIsValidProvider);
    return loginValid && passwordValid;
  },
);

/// Derived: whether submit button should be enabled
final loginSubmitEnabledProvider = Provider<bool>(
  (ref) {
    final isValid = ref.watch(loginFormIsValidProvider);
    final isSubmitting = ref.watch(loginIsSubmittingProvider);
    return isValid && !isSubmitting;
  },
);

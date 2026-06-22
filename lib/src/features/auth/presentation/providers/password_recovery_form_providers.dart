import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/core/forms/forms.dart' as app_forms;

/// Email field notifier for password recovery
final class PasswordRecoveryEmailFieldNotifier
    extends app_forms.StringFormFieldNotifier {
  @override
  String get initialValue => '';
}

/// Password recovery submission state notifier
final class PasswordRecoveryFormStateNotifier
    extends app_forms.FormStateNotifier {}

// ============================================================================
// FIELD PROVIDERS
// ============================================================================

final passwordRecoveryEmailFieldProvider = NotifierProvider<
    PasswordRecoveryEmailFieldNotifier,
    app_forms.FormFieldState<String>>(
  () => PasswordRecoveryEmailFieldNotifier(),
);

final passwordRecoveryFormStateProvider = NotifierProvider<
    PasswordRecoveryFormStateNotifier,
    app_forms.FormSubmissionState>(
  () => PasswordRecoveryFormStateNotifier(),
);

// ============================================================================
// EMAIL SELECTORS
// ============================================================================

final passwordRecoveryEmailValueProvider = Provider<String>((ref) {
  final state = ref.watch(passwordRecoveryEmailFieldProvider);
  return state.value;
});

final passwordRecoveryEmailErrorProvider = Provider<String?>((ref) {
  final state = ref.watch(passwordRecoveryEmailFieldProvider);
  return state.error;
});

final passwordRecoveryEmailIsValidProvider = Provider<bool>((ref) {
  final state = ref.watch(passwordRecoveryEmailFieldProvider);
  return state.isValid;
});

// ============================================================================
// FORM WIDE SELECTORS
// ============================================================================

final passwordRecoveryIsSubmittingProvider = Provider<bool>((ref) {
  final state = ref.watch(passwordRecoveryFormStateProvider);
  return state.isSubmitting;
});

final passwordRecoveryFormErrorProvider = Provider<String?>((ref) {
  final state = ref.watch(passwordRecoveryFormStateProvider);
  return state.generalError;
});

// ============================================================================
// FORM VALIDATION STATE
// ============================================================================

final passwordRecoveryFormIsValidProvider = Provider<bool>((ref) {
  return ref.watch(passwordRecoveryEmailIsValidProvider);
});

final passwordRecoverySubmitEnabledProvider = Provider<bool>((ref) {
  final isValid = ref.watch(passwordRecoveryFormIsValidProvider);
  final isSubmitting = ref.watch(passwordRecoveryIsSubmittingProvider);
  return isValid && !isSubmitting;
});

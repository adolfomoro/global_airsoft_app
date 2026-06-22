import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/core/forms/forms.dart' as app_forms;

// ============================================================================
// NOTIFIERS - Override initialValue and optional validator
// ============================================================================

/// Example field notifier - extend StringFormFieldNotifier
final class ExampleFieldNotifier extends app_forms.StringFormFieldNotifier {
  @override
  String get initialValue => '';

  // Optional: Override to add custom validation
  // @override
  // app_forms.AppFormFieldValidator<String> get validator => YourCustomValidator();
}

/// Example form submission state notifier
final class ExampleFormStateNotifier extends app_forms.FormStateNotifier {}

// ============================================================================
// PROVIDERS - Create one per field
// ============================================================================

final exampleFieldProvider =
    NotifierProvider<ExampleFieldNotifier, app_forms.FormFieldState<String>>(
  () => ExampleFieldNotifier(),
);

final exampleFormStateProvider =
    NotifierProvider<ExampleFormStateNotifier, app_forms.FormSubmissionState>(
  () => ExampleFormStateNotifier(),
);

// ============================================================================
// SELECTORS - Fine-grained watches for optimal rebuilds
// Use these in Consumer widgets to rebuild only on relevant changes
// ============================================================================

// --- Value Selectors ---
final exampleValueProvider = Provider<String>((ref) {
  final state = ref.watch(exampleFieldProvider);
  return state.value;
});

// --- Error Selectors ---
final exampleErrorProvider = Provider<String?>((ref) {
  final state = ref.watch(exampleFieldProvider);
  return state.error;
});

// --- Validation Selectors ---
final exampleIsValidProvider = Provider<bool>((ref) {
  final state = ref.watch(exampleFieldProvider);
  return state.isValid;
});

// --- Submission Selectors ---
final exampleIsSubmittingProvider = Provider<bool>((ref) {
  final state = ref.watch(exampleFormStateProvider);
  return state.isSubmitting;
});

final exampleFormErrorProvider = Provider<String?>((ref) {
  final state = ref.watch(exampleFormStateProvider);
  return state.generalError;
});

// ============================================================================
// FORM-WIDE VALIDATORS (Optional)
// ============================================================================

/// Derived: whether entire form is valid
final exampleFormIsValidProvider = Provider<bool>((ref) {
  final exampleValid = ref.watch(exampleIsValidProvider);
  // Add other field validations here if needed
  return exampleValid;
});

/// Derived: whether submit button should be enabled
final exampleSubmitEnabledProvider = Provider<bool>((ref) {
  final isValid = ref.watch(exampleFormIsValidProvider);
  final isSubmitting = ref.watch(exampleIsSubmittingProvider);
  return isValid && !isSubmitting;
});

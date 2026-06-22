import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents the overall state of a form submission process
/// (as opposed to individual field states)
final class FormSubmissionState {
  const FormSubmissionState({
    this.isSubmitting = false,
    this.generalError,
    this.wasSubmitted = false,
  });

  /// Whether form is currently being submitted
  final bool isSubmitting;

  /// General form error (not field-specific)
  final String? generalError;

  /// Whether form has been submitted at least once
  final bool wasSubmitted;

  /// Has any error (general or field-level would be checked by caller)
  bool get hasError => generalError != null && generalError!.isNotEmpty;

  FormSubmissionState copyWith({
    bool? isSubmitting,
    String? generalError,
    bool? wasSubmitted,
  }) {
    return FormSubmissionState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      generalError: generalError,
      wasSubmitted: wasSubmitted ?? this.wasSubmitted,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FormSubmissionState &&
          runtimeType == other.runtimeType &&
          isSubmitting == other.isSubmitting &&
          generalError == other.generalError &&
          wasSubmitted == other.wasSubmitted;

  @override
  int get hashCode =>
      isSubmitting.hashCode ^ generalError.hashCode ^ wasSubmitted.hashCode;

  @override
  String toString() =>
      'FormSubmissionState(isSubmitting: $isSubmitting, generalError: $generalError, wasSubmitted: $wasSubmitted)';
}

/// Generic notifier for managing form submission state
/// This handles loading/error states during form submission
base class FormStateNotifier extends Notifier<FormSubmissionState> {
  @override
  FormSubmissionState build() {
    return const FormSubmissionState();
  }

  /// Mark form as submitting
  void setSubmitting(bool value) {
    if (state.isSubmitting == value) {
      return;
    }
    state = state.copyWith(isSubmitting: value);
  }

  /// Set general form error
  void setError(String? error) {
    if (state.generalError == error) {
      return;
    }
    state = state.copyWith(generalError: error);
  }

  /// Mark as submitted
  void markSubmitted() {
    if (state.wasSubmitted) {
      return;
    }
    state = state.copyWith(wasSubmitted: true);
  }

  /// Reset form submission state
  void reset() {
    state = const FormSubmissionState();
  }

  /// Complete submission: stop loading, mark submitted
  void completeSubmission({String? error}) {
    state = FormSubmissionState(
      isSubmitting: false,
      generalError: error,
      wasSubmitted: true,
    );
  }
}

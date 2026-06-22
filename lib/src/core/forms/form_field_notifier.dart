import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/core/forms/form_field_state.dart';
import 'package:global_airsoft_app/src/core/forms/form_field_validator.dart';

/// Generic notifier for managing a single form field state.
/// Handles value changes, validation, touch tracking, and dirty state.
///
/// This is the core building block for form state management.
/// Each form field gets its own instance, enabling fine-grained reactivity
/// and optimal performance through Riverpod's .select() capability.
abstract base class FormFieldNotifier<T> extends Notifier<FormFieldState<T>> {
  /// Override to provide initial value
  T get initialValue;

  /// Override to provide validator (default: accepts anything)
  AppFormFieldValidator<T> get validator {
    return NoOpFormFieldValidator<T>();
  }

  @override
  FormFieldState<T> build() {
    return FormFieldState<T>(value: initialValue);
  }

  /// Update field value and validate
  /// Automatically marks as touched and dirty
  void setValue(T newValue) {
    final current = state;

    // Don't update if value hasn't actually changed
    if (current.value == newValue) {
      return;
    }

    // Validate new value
    final error = validator.validate(newValue);

    // Update state: value changes, error updates, mark as touched/dirty
    state = FormFieldState<T>(
      value: newValue,
      error: error,
      isTouched: true,
      isDirty: current.value != newValue,
    );
  }

  /// Mark field as touched (usually on blur/focus lost)
  void markTouched() {
    if (state.isTouched) {
      return; // Already touched
    }
    state = state.copyWith(isTouched: true);
  }

  /// Set error directly (useful for server-side errors)
  void setError(String? error) {
    if (state.error == error) {
      return; // No change
    }
    state = state.copyWith(error: error);
  }

  /// Clear error without changing value
  void clearError() {
    if (state.error == null) {
      return; // Already clear
    }
    state = state.copyWith(error: null);
  }

  /// Validate current value and update error
  /// Returns true if valid, false if has error
  bool validate() {
    final error = validator.validate(state.value);
    if (error == state.error) {
      return !state.hasError; // No change, return validity
    }
    state = state.copyWith(error: error);
    return error == null;
  }

  /// Reset field to initial state
  void reset() {
    state = FormFieldState<T>(value: initialValue);
  }
}

/// Specialized notifier for String fields with built-in common patterns
base class StringFormFieldNotifier extends FormFieldNotifier<String> {
  @override
  String get initialValue => '';
}

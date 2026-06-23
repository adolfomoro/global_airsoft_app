/// Represents the state of a single form field with strict null safety
/// and immutability for predictable state management.
const Object _formFieldStateNoChange = Object();
const Object _formFieldValueNoChange = Object();

final class FormFieldState<T> {
  const FormFieldState({
    required this.value,
    this.error,
    this.isTouched = false,
    this.isDirty = false,
  });

  /// Current value of the field
  final T value;

  /// Validation error message (null if valid)
  final String? error;

  /// Whether user has interacted with field
  final bool isTouched;

  /// Whether value has been changed from initial
  final bool isDirty;

  /// Whether field has validation error
  bool get hasError => error != null && error!.trim().isNotEmpty;

  /// Whether the current error should be visible to the user.
  bool get shouldShowError => isTouched && hasError;

  /// Whether field is in valid state
  bool get isValid => !hasError;

  /// Create a copy with selective field overrides
  FormFieldState<T> copyWith({
    Object? value = _formFieldValueNoChange,
    Object? error = _formFieldStateNoChange,
    bool? isTouched,
    bool? isDirty,
  }) {
    return FormFieldState<T>(
      value: identical(value, _formFieldValueNoChange)
          ? this.value
          : value as T,
      error: identical(error, _formFieldStateNoChange)
          ? this.error
          : error as String?,
      isTouched: isTouched ?? this.isTouched,
      isDirty: isDirty ?? this.isDirty,
    );
  }

  /// Mark field as touched without changing its value or error.
  FormFieldState<T> markAsTouched() {
    if (isTouched) {
      return this;
    }

    return copyWith(isTouched: true);
  }

  /// Mark field as dirty without changing the remaining state.
  FormFieldState<T> markAsDirty() {
    if (isDirty) {
      return this;
    }

    return copyWith(isDirty: true);
  }

  /// Clear the current error while preserving value and metadata.
  FormFieldState<T> clearError() {
    if (error == null) {
      return this;
    }

    return copyWith(error: null);
  }

  /// Reset field to initial state
  FormFieldState<T> reset(T initialValue) {
    return FormFieldState<T>(
      value: initialValue,
      error: null,
      isTouched: false,
      isDirty: false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FormFieldState<T> &&
          runtimeType == other.runtimeType &&
          value == other.value &&
          error == other.error &&
          isTouched == other.isTouched &&
          isDirty == other.isDirty;

  @override
  int get hashCode => Object.hash(value, error, isTouched, isDirty);

  @override
  String toString() =>
      'FormFieldState(value: $value, error: $error, isTouched: $isTouched, isDirty: $isDirty)';
}

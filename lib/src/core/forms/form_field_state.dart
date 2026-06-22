/// Represents the state of a single form field with strict null safety
/// and immutability for predictable state management.
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
  bool get hasError => error != null && error!.isNotEmpty;

  /// Whether field is in valid state
  bool get isValid => !hasError;

  /// Create a copy with selective field overrides
  FormFieldState<T> copyWith({
    T? value,
    String? error,
    bool? isTouched,
    bool? isDirty,
  }) {
    return FormFieldState<T>(
      value: value ?? this.value,
      error: error,
      isTouched: isTouched ?? this.isTouched,
      isDirty: isDirty ?? this.isDirty,
    );
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
  int get hashCode =>
      value.hashCode ^ error.hashCode ^ isTouched.hashCode ^ isDirty.hashCode;

  @override
  String toString() =>
      'FormFieldState(value: $value, error: $error, isTouched: $isTouched, isDirty: $isDirty)';
}

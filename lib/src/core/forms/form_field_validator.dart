import 'package:global_airsoft_app/src/core/forms/form_field_state.dart';

/// Validation rule contract - all rules must implement this
abstract interface class AppFormFieldValidationRule<T> {
  /// Validate and return error message or null if valid
  String? validate(T value);
}

/// Base implementation for field validators
abstract base class AppFormFieldValidator<T> {
  const AppFormFieldValidator({required this.rules});

  /// List of validation rules to apply in order
  final List<AppFormFieldValidationRule<T>> rules;

  /// Validate value against all rules, return first error or null
  String? validate(T value) {
    for (final rule in rules) {
      final error = rule.validate(value);
      if (error != null) {
        return error;
      }
    }
    return null;
  }

  /// Validate and return updated state with error
  FormFieldState<T> validateAndUpdate(FormFieldState<T> current) {
    final error = validate(current.value);
    if (error == current.error) {
      return current;
    }
    return current.copyWith(error: error);
  }
}

/// Default validator that accepts everything
final class NoOpFormFieldValidator<T> extends AppFormFieldValidator<T> {
  NoOpFormFieldValidator() : super(rules: const []);

  @override
  String? validate(T value) => null;
}

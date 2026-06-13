import 'package:global_airsoft_app/src/core/validation/validation_failure.dart';

abstract class ValidationRule {
  const ValidationRule();

  ValidationFailure? validate(String? value);
}

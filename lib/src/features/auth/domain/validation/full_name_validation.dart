import 'package:global_airsoft_app/src/core/validation/validation.dart';

abstract final class FullNameValidation {
  static const int minLength = 1;
  static const int maxLength = 256;

  static final ValidationRuleSet rules = ValidationRuleSet(<ValidationRule>[
    RequiredValidationRule(),
    MinLengthValidationRule(minLength),
    MaxLengthValidationRule(maxLength),
  ]);
}

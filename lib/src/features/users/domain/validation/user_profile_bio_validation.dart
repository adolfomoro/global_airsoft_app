import 'package:global_airsoft_app/src/core/validation/validation.dart';

abstract final class UserProfileBioValidation {
  static const int maxLength = 512;

  static final ValidationRuleSet rules = ValidationRuleSet(<ValidationRule>[
    MaxLengthValidationRule(maxLength),
  ]);
}

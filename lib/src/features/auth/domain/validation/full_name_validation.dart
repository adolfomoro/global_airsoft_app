import 'package:global_airsoft_app/src/core/validation/validation.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';

abstract final class FullNameValidation {
  static const int minLength = 5;
  static const int maxLength = 256;
  static final RegExp fullNamePattern = RegExp(r'^\S{2,}(?:\s+\S{2,})+$');

  static final ValidationRuleSet rules = ValidationRuleSet(<ValidationRule>[
    RequiredValidationRule(),
    PatternValidationRule(
      fullNamePattern,
      AppLocaleKeys.validationFullNameComplete,
      allowEmpty: false,
      trimValue: true,
    ),
    MaxLengthValidationRule(maxLength),
  ]);
}

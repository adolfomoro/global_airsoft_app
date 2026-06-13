import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/validation/validation.dart';

abstract final class FullNameValidation {
  static const int maxLength = 256;
  static final RegExp fullNamePattern = RegExp(r'^\S+(?:\s+\S+)+$');

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

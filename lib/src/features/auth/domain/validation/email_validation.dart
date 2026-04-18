import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/validation/validation.dart';

abstract final class EmailValidation {
  static const int maxLength = 255;
  static final RegExp emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static final ValidationRuleSet rules = ValidationRuleSet(<ValidationRule>[
    const RequiredValidationRule(),
    const MaxLengthValidationRule(maxLength),
    PatternValidationRule(
      emailPattern,
      AppLocaleKeys.validationPattern,
      allowEmpty: false,
      trimValue: true,
    ),
  ]);
}

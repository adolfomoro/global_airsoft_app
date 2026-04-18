import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/validation/validation.dart';

abstract final class UsernameValidation {
  static const int minLength = 3;
  static const int maxLength = 40;
  static final RegExp usernamePattern = RegExp(r'^[a-z]+$');

  static final ValidationRuleSet rules = ValidationRuleSet(<ValidationRule>[
    const RequiredValidationRule(),
    const MinLengthValidationRule(minLength),
    const MaxLengthValidationRule(maxLength),
    PatternValidationRule(
      usernamePattern,
      AppLocaleKeys.validationUsernameLowercaseOnly,
      allowEmpty: false,
      trimValue: true,
    ),
  ]);
}

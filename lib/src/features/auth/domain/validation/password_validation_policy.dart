import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/validation/validation.dart';

final class PasswordRequirementSpec {
  const PasswordRequirementSpec({required this.labelKey, required this.rule});

  final String labelKey;
  final ValidationRule rule;

  bool isSatisfied(String value) => rule.validate(value) == null;
}

abstract final class PasswordValidationPolicy {
  static const int minLength = 8;

  static final List<PasswordRequirementSpec> requirements =
      <PasswordRequirementSpec>[
        PasswordRequirementSpec(
          labelKey: AppLocaleKeys.authPasswordRulesMinimumLength,
          rule: MinLengthValidationRule(
            minLength,
            messageKey: AppLocaleKeys.validationMinLength,
          ),
        ),
        PasswordRequirementSpec(
          labelKey: AppLocaleKeys.authPasswordRulesLetterAndNumber,
          rule: PatternValidationRule(
            RegExp(r'^(?=.*[A-Za-z])(?=.*\d).+$'),
            AppLocaleKeys.validationPasswordLetterAndNumber,
            allowEmpty: false,
          ),
        ),
        PasswordRequirementSpec(
          labelKey: AppLocaleKeys.authPasswordRulesSpecialCharacter,
          rule: PatternValidationRule(
            RegExp(r'.*[^a-zA-Z0-9].*'),
            AppLocaleKeys.validationPasswordSpecialCharacter,
            allowEmpty: false,
          ),
        ),
      ];

  static final ValidationRuleSet rules = ValidationRuleSet(<ValidationRule>[
    const RequiredValidationRule(),
    ...requirements.map((PasswordRequirementSpec spec) => spec.rule),
  ]);
}

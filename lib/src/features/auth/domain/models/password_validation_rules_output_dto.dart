import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/validation/rules/min_length_validation_rule.dart';
import 'package:global_airsoft_app/src/core/validation/rules/pattern_validation_rule.dart';
import 'package:global_airsoft_app/src/core/validation/rules/required_validation_rule.dart';
import 'package:global_airsoft_app/src/core/validation/rules/unique_characters_validation_rule.dart';
import 'package:global_airsoft_app/src/core/validation/validation_rule.dart';
import 'package:global_airsoft_app/src/core/validation/validation_rule_set.dart';

final class PasswordValidationRulesOutputDto {
  const PasswordValidationRulesOutputDto({
    required this.requiredLength,
    required this.requiredUniqueChars,
    required this.requireNonAlphanumeric,
    required this.requireDigit,
    required this.requireLowercase,
    required this.requireUppercase,
  });

  final int requiredLength;
  final int requiredUniqueChars;
  final bool requireNonAlphanumeric;
  final bool requireDigit;
  final bool requireLowercase;
  final bool requireUppercase;

  factory PasswordValidationRulesOutputDto.fromJson(Map<String, dynamic> json) {
    return PasswordValidationRulesOutputDto(
      requiredLength: (json['requiredLength'] as num?)?.toInt() ?? 0,
      requiredUniqueChars: (json['requiredUniqueChars'] as num?)?.toInt() ?? 0,
      requireNonAlphanumeric:
          (json['requireNonAlphanumeric'] as bool?) ?? false,
      requireDigit: (json['requireDigit'] as bool?) ?? false,
      requireLowercase: (json['requireLowercase'] as bool?) ?? false,
      requireUppercase: (json['requireUppercase'] as bool?) ?? false,
    );
  }

  ValidationRuleSet toValidationRuleSet() {
    final List<ValidationRule> rules = <ValidationRule>[
      const RequiredValidationRule(),
      if (requiredLength > 0)
        MinLengthValidationRule(
          requiredLength,
          messageKey: AppLocaleKeys.validationPasswordMinimumLength,
        ),
      if (requiredUniqueChars > 0)
        UniqueCharactersValidationRule(
          requiredUniqueChars,
          messageKey: AppLocaleKeys.validationPasswordUniqueCharacters,
        ),
      if (requireDigit)
        PatternValidationRule(
          RegExp(r'.*\d.*'),
          allowEmpty: false,
          messageKey: AppLocaleKeys.validationPasswordRequireDigit,
        ),
      if (requireLowercase)
        PatternValidationRule(
          RegExp(r'.*[a-z].*'),
          allowEmpty: false,
          messageKey: AppLocaleKeys.validationPasswordRequireLowercase,
        ),
      if (requireUppercase)
        PatternValidationRule(
          RegExp(r'.*[A-Z].*'),
          allowEmpty: false,
          messageKey: AppLocaleKeys.validationPasswordRequireUppercase,
        ),
      if (requireNonAlphanumeric)
        PatternValidationRule(
          RegExp(r'.*[^a-zA-Z0-9].*'),
          allowEmpty: false,
          messageKey: AppLocaleKeys.validationPasswordRequireNonAlphanumeric,
        ),
    ];

    return ValidationRuleSet(rules);
  }
}

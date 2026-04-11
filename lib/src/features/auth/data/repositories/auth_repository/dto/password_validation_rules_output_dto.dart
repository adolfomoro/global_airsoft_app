import 'package:global_airsoft_app/src/core/validation/rules/required_validation_rule.dart';
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
      // ...existing code...
    ];
    return ValidationRuleSet(rules);
  }
}

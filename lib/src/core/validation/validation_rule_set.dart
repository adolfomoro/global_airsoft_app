import 'package:global_airsoft_app/src/core/validation/rules/required_validation_rule.dart';
import 'package:global_airsoft_app/src/core/validation/validation_failure.dart';
import 'package:global_airsoft_app/src/core/validation/validation_rule.dart';

typedef ValidationMessageResolver = String Function(ValidationFailure failure);

final class ValidationRuleSet {
  const ValidationRuleSet(this.rules);

  final List<ValidationRule> rules;

  bool get hasRequiredRule => rules.any((ValidationRule rule) {
    return rule is RequiredValidationRule;
  });

  ValidationFailure? validate(String? value) {
    for (final ValidationRule rule in rules) {
      final ValidationFailure? failure = rule.validate(value);
      if (failure != null) {
        return failure;
      }
    }

    return null;
  }

  String? Function(String?) asValidator(ValidationMessageResolver resolver) {
    return (String? value) {
      final ValidationFailure? failure = validate(value);
      if (failure == null) {
        return null;
      }

      return resolver(failure);
    };
  }
}

import 'package:global_airsoft_app/src/core/validation/validation_failure.dart';
import 'package:global_airsoft_app/src/core/validation/validation_rule.dart';

final class PatternValidationRule extends ValidationRule {
  const PatternValidationRule(
    this.pattern,
    this.messageKey, {
    this.allowEmpty = true,
    this.trimValue = false,
    this.arguments = const <String, Object?>{},
  });

  final RegExp pattern;
  final String messageKey;
  final bool allowEmpty;
  final bool trimValue;
  final Map<String, Object?> arguments;

  @override
  ValidationFailure? validate(String? value) {
    final String normalizedValue = trimValue
        ? value?.trim() ?? ''
        : value ?? '';
    if (normalizedValue.isEmpty && allowEmpty) {
      return null;
    }

    if (pattern.hasMatch(normalizedValue)) {
      return null;
    }

    return ValidationFailure(messageKey: messageKey, arguments: arguments);
  }
}

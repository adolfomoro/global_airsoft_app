import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/validation/validation_failure.dart';
import 'package:global_airsoft_app/src/core/validation/validation_rule.dart';

final class MinLengthValidationRule extends ValidationRule {
  const MinLengthValidationRule(
    this.minLength, {
    this.messageKey = AppLocaleKeys.validationMinLength,
    this.trimValue = false,
  }) : assert(minLength >= 0);

  final int minLength;
  final String messageKey;
  final bool trimValue;

  @override
  ValidationFailure? validate(String? value) {
    final String normalizedValue = trimValue
        ? value?.trim() ?? ''
        : value ?? '';
    if (normalizedValue.length >= minLength) {
      return null;
    }

    return ValidationFailure(
      messageKey: messageKey,
      arguments: <String, Object?>{'min': minLength},
    );
  }
}

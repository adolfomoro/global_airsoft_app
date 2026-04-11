import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/validation/validation_failure.dart';
import 'package:global_airsoft_app/src/core/validation/validation_rule.dart';

final class MaxLengthValidationRule extends ValidationRule {
  const MaxLengthValidationRule(
    this.maxLength, {
    this.messageKey = AppLocaleKeys.validationMaxLength,
    this.trimValue = false,
  }) : assert(maxLength >= 0);

  final int maxLength;
  final String messageKey;
  final bool trimValue;

  @override
  ValidationFailure? validate(String? value) {
    final String normalizedValue = trimValue
        ? value?.trim() ?? ''
        : value ?? '';
    if (normalizedValue.length <= maxLength) {
      return null;
    }

    return ValidationFailure(
      messageKey: messageKey,
      arguments: <String, Object?>{'max': maxLength},
    );
  }
}

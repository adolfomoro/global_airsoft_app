import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/validation/validation_failure.dart';
import 'package:global_airsoft_app/src/core/validation/validation_rule.dart';

final class RequiredValidationRule extends ValidationRule {
  const RequiredValidationRule({
    this.messageKey = AppLocaleKeys.validationRequired,
    this.trimValue = true,
  });

  final String messageKey;
  final bool trimValue;

  @override
  ValidationFailure? validate(String? value) {
    final String normalizedValue = trimValue
        ? value?.trim() ?? ''
        : value ?? '';
    if (normalizedValue.isNotEmpty) {
      return null;
    }

    return ValidationFailure(messageKey: messageKey);
  }
}

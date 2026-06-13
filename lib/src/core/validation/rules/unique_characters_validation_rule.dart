import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/validation/validation_failure.dart';
import 'package:global_airsoft_app/src/core/validation/validation_rule.dart';

final class UniqueCharactersValidationRule extends ValidationRule {
  const UniqueCharactersValidationRule(
    this.minUniqueCharacters, {
    this.messageKey = AppLocaleKeys.validationPattern,
    this.trimValue = false,
  }) : assert(minUniqueCharacters >= 0);

  final int minUniqueCharacters;
  final String messageKey;
  final bool trimValue;

  @override
  ValidationFailure? validate(String? value) {
    final String normalizedValue = trimValue
        ? value?.trim() ?? ''
        : value ?? '';

    if (_uniqueCharacterCount(normalizedValue) >= minUniqueCharacters) {
      return null;
    }

    return ValidationFailure(
      messageKey: messageKey,
      arguments: <String, Object?>{'min': minUniqueCharacters},
    );
  }

  int _uniqueCharacterCount(String value) {
    return value.runes.toSet().length;
  }
}

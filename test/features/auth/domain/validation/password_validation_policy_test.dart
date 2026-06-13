import 'package:flutter_test/flutter_test.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/features/auth/domain/validation/password_validation_policy.dart';

void main() {
  test('accepts a password that matches all fixed rules', () {
    expect(PasswordValidationPolicy.rules.validate('Abc123!x'), isNull);
  });

  test('requires at least eight characters', () {
    final failure = PasswordValidationPolicy.rules.validate('Abc12!');

    expect(failure, isNotNull);
    expect(failure?.messageKey, AppLocaleKeys.validationMinLength);
  });

  test('requires a letter and a number together', () {
    final failure = PasswordValidationPolicy.rules.validate('12345678');

    expect(failure, isNotNull);
    expect(
      failure?.messageKey,
      AppLocaleKeys.validationPasswordLetterAndNumber,
    );
  });

  test('requires a special character', () {
    final failure = PasswordValidationPolicy.rules.validate('Abc12345');

    expect(failure, isNotNull);
    expect(
      failure?.messageKey,
      AppLocaleKeys.validationPasswordSpecialCharacter,
    );
  });
}

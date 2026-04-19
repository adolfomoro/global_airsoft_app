import 'package:flutter_test/flutter_test.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/features/auth/domain/validation/full_name_validation.dart';

void main() {
  test('accepts a complete full name with first and last name', () {
    expect(FullNameValidation.rules.validate('Joao Silva'), isNull);
    expect(FullNameValidation.rules.validate('João da Silva'), isNull);
  });

  test('rejects a single word full name', () {
    final failure = FullNameValidation.rules.validate('Joao');

    expect(failure, isNotNull);
    expect(failure?.messageKey, AppLocaleKeys.validationFullNameComplete);
  });

  test('rejects names with a one-character second word', () {
    final failure = FullNameValidation.rules.validate('Joao A');

    expect(failure, isNotNull);
    expect(failure?.messageKey, AppLocaleKeys.validationFullNameComplete);
  });
}

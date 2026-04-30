import 'package:flutter_test/flutter_test.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/features/auth/domain/validation/username_validation.dart';

void main() {
  test('accepts lowercase usernames with digits, underscore, and dot', () {
    expect(UsernameValidation.rules.validate('john'), isNull);
    expect(UsernameValidation.rules.validate('john123'), isNull);
    expect(UsernameValidation.rules.validate('john_doe'), isNull);
    expect(UsernameValidation.rules.validate('john.doe'), isNull);
  });

  test('rejects invalid username characters', () {
    final failure = UsernameValidation.rules.validate('John-Doe');

    expect(failure, isNotNull);
    expect(failure?.messageKey, AppLocaleKeys.validationUsernameLowercaseOnly);
  });
}

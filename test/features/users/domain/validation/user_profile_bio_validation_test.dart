import 'package:flutter_test/flutter_test.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/features/users/domain/validation/user_profile_bio_validation.dart';

void main() {
  test('accepts an empty bio', () {
    expect(UserProfileBioValidation.rules.validate(''), isNull);
  });

  test('accepts a bio up to the backend max length', () {
    final String bio = 'a' * UserProfileBioValidation.maxLength;

    expect(UserProfileBioValidation.rules.validate(bio), isNull);
  });

  test('rejects a bio that exceeds the backend max length', () {
    final String bio = 'a' * (UserProfileBioValidation.maxLength + 1);
    final failure = UserProfileBioValidation.rules.validate(bio);

    expect(failure, isNotNull);
    expect(failure?.messageKey, AppLocaleKeys.validationMaxLength);
  });
}

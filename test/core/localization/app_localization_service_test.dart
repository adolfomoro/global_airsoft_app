import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localization_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('resolves translations from the current locale resolver', () async {
    Locale locale = const Locale('en');
    final AppLocalizationService service = AppLocalizationService(
      localeResolver: () => locale,
    );

    expect(await service.tr(AppLocaleKeys.profilePhotoTryAgain), 'Try again');

    locale = const Locale('pt', 'BR');

    expect(
      await service.tr(AppLocaleKeys.profilePhotoTryAgain),
      'Tentar novamente',
    );
  });
}

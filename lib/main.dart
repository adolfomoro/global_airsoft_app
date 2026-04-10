import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/app/app.dart';
import 'package:global_airsoft_app/src/app/app_providers.dart';
import 'package:global_airsoft_app/src/app/bootstrap.dart';
import 'package:global_airsoft_app/src/app/theme/theme_preference.dart';
import 'package:global_airsoft_app/src/app/theme/theme_preference_service.dart';
import 'package:global_airsoft_app/src/app/theme/theme_providers.dart';
import 'package:global_airsoft_app/src/core/config/app_config.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_providers.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_service.dart';
import 'package:global_airsoft_app/src/core/monitoring/app_telemetry.dart';
import 'package:global_airsoft_app/src/core/storage/shared_prefs_key_value_store.dart';

Future<void> main() async {
  final AppConfig appConfig = AppConfig.fromDartDefines();
  await AppTelemetry.instance.initialize(appConfig);

  await bootstrap(
    builder: () async {
      final SharedPrefsKeyValueStore keyValueStore =
          await SharedPrefsKeyValueStore.create();
      final ThemePreferenceService themePreferenceService =
          ThemePreferenceService(store: keyValueStore);
      final AppThemePreference initialThemePreference = themePreferenceService
          .readPreference();
      final AppLocaleService appLocaleService = AppLocaleService(
        store: keyValueStore,
      );
      final AppLocaleBootstrapData localeBootstrapData = await appLocaleService
          .initializeFromDevice();

      return BootstrapPayload(
        initialBrightness: initialThemePreference.brightness,
        app: ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(appConfig),
            themePreferenceServiceProvider.overrideWithValue(
              themePreferenceService,
            ),
            initialThemePreferenceProvider.overrideWithValue(
              initialThemePreference,
            ),
            appLocaleServiceProvider.overrideWithValue(appLocaleService),
            initialAppLocaleProvider.overrideWithValue(
              localeBootstrapData.initialUiLocale,
            ),
            initialOsLanguageTagProvider.overrideWithValue(
              localeBootstrapData.osLanguageTag,
            ),
          ],
          child: const App(),
        ),
      );
    },
  );
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/app/app.dart';
import 'package:global_airsoft_app/src/app/bootstrap.dart';
import 'package:global_airsoft_app/src/app/theme/theme_preference.dart';
import 'package:global_airsoft_app/src/app/theme/theme_preference_service.dart';
import 'package:global_airsoft_app/src/app/theme/theme_providers.dart';
import 'package:global_airsoft_app/src/core/storage/shared_prefs_key_value_store.dart';

Future<void> main() async {
  await bootstrap(
    builder: () async {
      final SharedPrefsKeyValueStore keyValueStore =
          await SharedPrefsKeyValueStore.create();
      final ThemePreferenceService themePreferenceService =
          ThemePreferenceService(store: keyValueStore);
      final AppThemePreference initialThemePreference = themePreferenceService
          .readPreference();

      return BootstrapPayload(
        initialBrightness: initialThemePreference.brightness,
        app: ProviderScope(
          overrides: <Override>[
            themePreferenceServiceProvider.overrideWithValue(
              themePreferenceService,
            ),
            initialThemePreferenceProvider.overrideWithValue(
              initialThemePreference,
            ),
          ],
          child: const App(),
        ),
      );
    },
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/app/app.dart';
import 'package:global_airsoft_app/src/app/app_providers.dart';
import 'package:global_airsoft_app/src/app/bootstrap.dart';
import 'package:global_airsoft_app/src/core/config/app_config.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_providers.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_service.dart';
import 'package:global_airsoft_app/src/core/monitoring/app_telemetry.dart';
import 'package:global_airsoft_app/src/core/storage/secure_storage_service.dart';
import 'package:global_airsoft_app/src/core/storage/secure_storage_service_impl.dart';
import 'package:global_airsoft_app/src/core/storage/storage_providers.dart';

Future<void> main() async {
  final AppConfig appConfig = AppConfig.fromDartDefines();
  await AppTelemetry.instance.initialize(appConfig);

  await bootstrap(
    builder: () async {
      final SecureStorageService secureStorageService =
          SecureStorageServiceImpl.create();
      final SharedPrefsKeyValueStore keyValueStore =
          await SharedPrefsKeyValueStore.create();
      final AppLocaleService appLocaleService = AppLocaleService(
        store: keyValueStore,
      );
      final AppLocaleBootstrapData localeBootstrapData = await appLocaleService
          .initializeFromDevice();

      return BootstrapPayload(
        initialBrightness: Brightness.dark,
        app: ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(appConfig),
            secureStorageServiceProvider.overrideWithValue(
              secureStorageService,
            ),
            sharedPrefsKeyValueStoreProvider.overrideWithValue(keyValueStore),
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

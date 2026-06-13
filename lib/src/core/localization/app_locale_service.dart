import 'dart:ui';

import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/core/storage/key_value_store.dart';

final class AppLocaleBootstrapData {
  const AppLocaleBootstrapData({
    required this.initialUiLocale,
    required this.osLanguageTag,
  });

  final Locale initialUiLocale;
  final String osLanguageTag;
}

final class AppLocaleService {
  AppLocaleService({required KeyValueStore store}) : _store = store;

  static const String uiLocaleKey = 'app_ui_locale';

  final KeyValueStore _store;

  Future<AppLocaleBootstrapData> initializeFromDevice() async {
    final Locale osLocale = AppLocalizations.resolveFromPreferred(
      PlatformDispatcher.instance.locales,
    );
    final String osLanguageTag = AppLocalizations.toLanguageTag(osLocale);

    final String? storedTag = _store.getString(uiLocaleKey);
    final String? normalizedStoredTag = AppLocalizations.normalizeLanguageTag(
      storedTag,
    );

    if (normalizedStoredTag == null) {
      await _store.setString(uiLocaleKey, osLanguageTag);
      return AppLocaleBootstrapData(
        initialUiLocale: osLocale,
        osLanguageTag: osLanguageTag,
      );
    }

    return AppLocaleBootstrapData(
      initialUiLocale: AppLocalizations.resolveFromLanguageTag(
        normalizedStoredTag,
      ),
      osLanguageTag: osLanguageTag,
    );
  }

  Future<void> saveUiLocale(Locale locale) async {
    await _store.setString(uiLocaleKey, AppLocalizations.toLanguageTag(locale));
  }
}

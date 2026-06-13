import 'dart:ui';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';

final class AppLocalizationService {
  static const AppLocalizationsDelegate _delegate = AppLocalizationsDelegate();

  AppLocalizationService({Locale? locale, Locale Function()? localeResolver})
    : _locale = locale,
      _localeResolver = localeResolver {
    assert(
      locale != null || localeResolver != null,
      'Either locale or localeResolver must be provided.',
    );
  }

  final Locale? _locale;
  final Locale Function()? _localeResolver;
  final Map<String, Future<AppLocalizations>> _localizationsCache =
      <String, Future<AppLocalizations>>{};

  Future<String> tr(String key) async {
    final AppLocalizations l10n = await _loadLocalizations();
    return l10n.tr(key);
  }

  Future<String> trArgs(
    String key, {
    Map<String, Object?> args = const <String, Object?>{},
  }) async {
    final AppLocalizations l10n = await _loadLocalizations();
    return l10n.trArgs(key, args: args);
  }

  Future<AppLocalizations> _loadLocalizations() {
    final Locale locale = _localeResolver?.call() ?? _locale!;
    final String languageTag = AppLocalizations.toLanguageTag(locale);

    return _localizationsCache.putIfAbsent(languageTag, () {
      return _delegate.load(locale);
    });
  }
}

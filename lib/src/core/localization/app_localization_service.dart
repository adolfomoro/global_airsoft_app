import 'dart:ui';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';

final class AppLocalizationService {
  static const AppLocalizationsDelegate _delegate = AppLocalizationsDelegate();

  AppLocalizationService({required Locale locale})
    : _locale = locale,
      _localizationsFuture = _delegate.load(locale);

  final Locale _locale;
  final Future<AppLocalizations> _localizationsFuture;

  Locale get locale => _locale;

  Future<String> tr(String key) {
    return _localizationsFuture.then((AppLocalizations l10n) => l10n.tr(key));
  }

  Future<String> trArgs(
    String key, {
    Map<String, Object?> args = const <String, Object?>{},
  }) {
    return _localizationsFuture.then(
      (AppLocalizations l10n) => l10n.trArgs(key, args: args),
    );
  }
}

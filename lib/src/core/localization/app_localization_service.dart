import 'dart:ui';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';

final class AppLocalizationService {
  AppLocalizationService({required Locale locale})
    : _locale = locale,
      _localizationsFuture = AppLocalizationsDelegate().load(locale);

  final Locale _locale;
  final Future<AppLocalizations> _localizationsFuture;

  Locale get locale => _locale;

  Future<String> tr(String key) async {
    final AppLocalizations localizations = await _localizationsFuture;
    return localizations.tr(key);
  }

  Future<String> trArgs(
    String key, {
    Map<String, Object?> args = const <String, Object?>{},
  }) async {
    final AppLocalizations localizations = await _localizationsFuture;
    return localizations.trArgs(key, args: args);
  }
}

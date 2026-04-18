import 'dart:ui';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';

final class AppLocalizationService {
  static const AppLocalizationsDelegate _delegate = AppLocalizationsDelegate();

  AppLocalizationService({required Locale locale})
    : _localizationsFuture = _delegate.load(locale);

  final Future<AppLocalizations> _localizationsFuture;

  Future<String> tr(String key) async {
    final AppLocalizations l10n = await _localizationsFuture;
    return l10n.tr(key);
  }

  Future<String> trArgs(
    String key, {
    Map<String, Object?> args = const <String, Object?>{},
  }) async {
    final AppLocalizations l10n = await _localizationsFuture;
    return l10n.trArgs(key, args: args);
  }
}

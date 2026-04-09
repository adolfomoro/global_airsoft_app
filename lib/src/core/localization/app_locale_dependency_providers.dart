import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_service.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';

final Provider<AppLocaleService> appLocaleServiceProvider =
    Provider<AppLocaleService>(
      (Ref ref) => throw UnimplementedError('AppLocaleService not set.'),
    );

final Provider<Locale> initialAppLocaleProvider = Provider<Locale>(
  (Ref ref) => AppLocalizations.fallbackLocale,
);

final Provider<String> initialOsLanguageTagProvider = Provider<String>(
  (Ref ref) => AppLocalizations.toLanguageTag(AppLocalizations.fallbackLocale),
);
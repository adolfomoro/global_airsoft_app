import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_controller.dart';
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

final StateNotifierProvider<AppLocaleController, Locale>
appLocaleControllerProvider =
    StateNotifierProvider<AppLocaleController, Locale>((Ref ref) {
      final AppLocaleService service = ref.watch(appLocaleServiceProvider);
      final Locale initialUiLocale = ref.watch(initialAppLocaleProvider);

      return AppLocaleController(
        localeService: service,
        initialUiLocale: initialUiLocale,
      );
    });

final Provider<bool> hasPendingServerLocaleChangeProvider = Provider<bool>((
  Ref ref,
) {
  final AppLocaleController controller = ref.watch(
    appLocaleControllerProvider.notifier,
  );
  ref.watch(appLocaleControllerProvider);
  return controller.hasPendingServerLocaleChange;
});

final Provider<String> appOsLanguageTagProvider = Provider<String>((Ref ref) {
  return ref.watch(initialOsLanguageTagProvider);
});

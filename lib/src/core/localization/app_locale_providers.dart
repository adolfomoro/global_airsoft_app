import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_controller.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_dependency_providers.dart';
import 'package:global_airsoft_app/src/core/localization/app_localization_service.dart';

export 'package:global_airsoft_app/src/core/localization/app_locale_dependency_providers.dart';

final NotifierProvider<AppLocaleController, Locale>
appLocaleControllerProvider = NotifierProvider<AppLocaleController, Locale>(
  AppLocaleController.new,
);

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

final Provider<AppLocalizationService> appLocalizationServiceProvider =
    Provider<AppLocalizationService>(
      (Ref ref) => throw UnimplementedError('AppLocalizationService not set.'),
    );

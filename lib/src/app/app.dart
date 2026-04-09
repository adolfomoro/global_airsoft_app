import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/app/theme/app_theme.dart';
import 'package:global_airsoft_app/src/app/theme/theme_providers.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_providers.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/features/home/presentation/pages/home_page.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<ThemeMode>(themePreferenceControllerProvider, (
      ThemeMode? previous,
      ThemeMode next,
    ) {
      final Brightness brightness = next == ThemeMode.light
          ? Brightness.light
          : Brightness.dark;
      SystemChrome.setSystemUIOverlayStyle(
        AppTheme.overlayStyleFor(brightness),
      );
    });

    final ThemeMode themeMode = ref.watch(themePreferenceControllerProvider);
    final Locale locale = ref.watch(appLocaleControllerProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (BuildContext context) {
        return context.l10n.tr(AppLocaleKeys.appTitle);
      },
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: const HomePage(),
    );
  }
}

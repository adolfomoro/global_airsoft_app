import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/core/widgets/app_unfocus_wrapper.dart';
import 'package:global_airsoft_app/src/app/app_providers.dart';
import 'package:global_airsoft_app/src/app/theme/app_theme.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_providers.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/pages/login_page.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:global_airsoft_app/src/features/home/presentation/pages/home_page.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  @override
  void initState() {
    super.initState();
    unawaited(_initializeDeviceRegistration());
  }

  Future<void> _initializeDeviceRegistration() async {
    final service = ref.read(deviceRegistrationServiceProvider);
    await service.initialize();
    await service.registerInBackground();
  }

  @override
  Widget build(BuildContext context) {
    final Locale locale = ref.watch(appLocaleControllerProvider);
    final AsyncValue<bool> isAuthenticatedAsync = ref.watch(
      isAuthenticatedProvider,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (BuildContext context, Widget? child) {
        return AppUnfocusWrapper(child: child ?? const SizedBox.shrink());
      },
      onGenerateTitle: (BuildContext context) {
        return context.l10n.tr(AppLocaleKeys.appTitle);
      },
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: isAuthenticatedAsync.when(
        data: (bool isAuthenticated) {
          return isAuthenticated ? const HomePage() : const LoginPage();
        },
        loading: () {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        },
        error: (Object error, StackTrace stackTrace) {
          return const LoginPage();
        },
      ),
    );
  }
}

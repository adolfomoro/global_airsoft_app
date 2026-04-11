import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/core/widgets/app_unfocus_wrapper.dart';
import 'package:global_airsoft_app/src/app/app_providers.dart';
import 'package:global_airsoft_app/src/app/theme/app_theme.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_providers.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/core/logging/app_logger.dart';
import 'package:global_airsoft_app/src/core/notifications/widgets/notification_permission_listener.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/pages/login_page.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:global_airsoft_app/src/features/home/presentation/pages/home_page.dart';

final GlobalKey<NavigatorState> _appNavigatorKey = GlobalKey<NavigatorState>();

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  @override
  void initState() {
    super.initState();
    unawaited(_initializeStartupServices());
  }

  Future<void> _initializeStartupServices() async {
    try {
      await _initializePushNotifications();
    } catch (error, stackTrace) {
      AppLogger.instance.error(
        'Push notification initialization failed.',
        error: error,
        stackTrace: stackTrace,
      );
    }

    try {
      await _initializeDeviceRegistration();
    } catch (error, stackTrace) {
      AppLogger.instance.error(
        'Device registration startup failed.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _initializePushNotifications() async {
    final pushNotificationService = ref.read(pushNotificationServiceProvider);
    await pushNotificationService.initialize(
      onTokenUpdated: (String token) async {
        ref.read(pushTokenProvider.notifier).setToken(token);
        await ref
            .read(deviceRegistrationServiceProvider)
            .registerInBackground();
      },
    );
  }

  Future<void> _initializeDeviceRegistration() async {
    final service = ref.read(deviceRegistrationServiceProvider);
    await service.initialize();
    await service.registerInBackground();
  }

  @override
  Widget build(BuildContext context) {
    final Locale locale = ref.watch(appLocaleControllerProvider);
    final bool isAuthenticated = ref.watch(isAuthenticatedProvider);

    return MaterialApp(
      navigatorKey: _appNavigatorKey,
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (BuildContext context) {
        return context.l10n.tr(AppLocaleKeys.appTitle);
      },
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: isAuthenticated ? const HomePage() : const LoginPage(),
      builder: (BuildContext context, Widget? child) {
        return NotificationPermissionListener(
          navigatorKey: _appNavigatorKey,
          child: AppUnfocusWrapper(child: child ?? const SizedBox.shrink()),
        );
      },
    );
  }
}

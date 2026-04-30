import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/app/app_navigator.dart';
import 'package:global_airsoft_app/src/app/app_providers.dart';
import 'package:global_airsoft_app/src/app/routing/app_route_paths.dart';
import 'package:global_airsoft_app/src/app/routing/app_routes.dart';
import 'package:global_airsoft_app/src/app/theme/app_theme.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_providers.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/core/logging/app_logger.dart';
import 'package:global_airsoft_app/src/core/notifications/widgets/notification_permission_listener.dart';
import 'package:global_airsoft_app/src/core/widgets/app_unfocus_wrapper.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/providers/auth_providers.dart';

class GlobalAirsoftApp extends ConsumerStatefulWidget {
  const GlobalAirsoftApp({super.key});

  @override
  ConsumerState<GlobalAirsoftApp> createState() => _GlobalAirsoftAppState();
}

class _GlobalAirsoftAppState extends ConsumerState<GlobalAirsoftApp> {
  ProviderSubscription<bool>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = ref.listenManual<bool>(isAuthenticatedProvider, (
      bool? previous,
      bool next,
    ) {
      if (previous == null || previous == next) {
        return;
      }

      final NavigatorState? navigatorState = appNavigatorKey.currentState;
      if (navigatorState == null || !navigatorState.mounted) {
        return;
      }

      final String targetRoute = next
          ? AppRoutePaths.home
          : AppRoutePaths.login;
      navigatorState.pushNamedAndRemoveUntil(targetRoute, (_) => false);
    });
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

  @override
  void dispose() {
    _authSubscription?.close();
    _authSubscription = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Locale locale = ref.watch(appLocaleControllerProvider);
    final bool isAuthenticated = ref.watch(isAuthenticatedProvider);

    return MaterialApp(
      navigatorKey: appNavigatorKey,
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
      initialRoute: isAuthenticated ? AppRoutePaths.home : AppRoutePaths.login,
      onGenerateInitialRoutes: (String initialRouteName) {
        return AppRoutes.onGenerateInitialRoutes(
          initialRouteName,
          isAuthenticated: () => ref.read(isAuthenticatedProvider),
        );
      },
      onGenerateRoute: (RouteSettings settings) {
        return AppRoutes.onGenerateRoute(
          settings,
          isAuthenticated: () => ref.read(isAuthenticatedProvider),
        );
      },
      builder: (BuildContext context, Widget? child) {
        return NotificationPermissionListener(
          navigatorKey: appNavigatorKey,
          child: AppUnfocusWrapper(child: child ?? const SizedBox.shrink()),
        );
      },
    );
  }
}

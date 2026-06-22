import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/app/app_bootstrap.dart';
import 'package:global_airsoft_app/src/app/app_navigator.dart';
import 'package:global_airsoft_app/src/app/app_providers.dart';
import 'package:global_airsoft_app/src/app/bootstrap/app_bootstrap_providers.dart'
  hide initialAppLocaleProvider;
import 'package:global_airsoft_app/src/app/bootstrap/app_dependencies_bootstrapper.dart';
import 'package:global_airsoft_app/src/app/global_airsoft_app.dart';
import 'package:global_airsoft_app/src/app/startup/app_startup_orchestrator.dart';
import 'package:global_airsoft_app/src/core/config/app_config.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_providers.dart';
import 'package:global_airsoft_app/src/core/localization/app_localization_service.dart';
import 'package:global_airsoft_app/src/core/monitoring/app_telemetry.dart';
import 'package:global_airsoft_app/src/core/notifications/push_notification_service.dart';
import 'package:global_airsoft_app/src/core/widgets/app_snack_bar_presenter.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:global_airsoft_app/src/features/users/application/providers/users_providers.dart';

Future<void> main() async {
  final AppConfig appConfig = AppConfig.fromDartDefines();
  await AppTelemetry.instance.initialize(appConfig);

  await bootstrapApp(
    builder: () async {
      PushNotificationService.registerBackgroundHandler();

      // Initialize all dependencies asynchronously
      final AppDependenciesBootstrapData bootstrapData =
          await AppDependenciesBootstrapper.bootstrap();

      late final ProviderContainer container;
      final AppLocalizationService appLocalizationService =
          AppLocalizationService(
            localeResolver: () => container.read(appLocaleControllerProvider),
          );

      // Create container with minimal overrides
      container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(appConfig),
          appBootstrapDataProvider.overrideWithValue(bootstrapData),
          appLocaleServiceProvider.overrideWithValue(
            bootstrapData.appLocaleService,
          ),
          initialAppLocaleProvider.overrideWithValue(
            bootstrapData.localeBootstrapData.initialUiLocale,
          ),
          appLocalizationServiceProvider.overrideWithValue(
            appLocalizationService,
          ),
          authLocalSessionCleanupProvider.overrideWithValue(() async {
            container.read(currentUserProfileRefreshRequestProvider.notifier)
                .clear();
            await container.read(currentUserProfileProvider.notifier)
                .clearCachedProfile();
          }),
        ],
      );

      final AppStartupOrchestrator appStartupOrchestrator = container.read(
        appStartupOrchestratorProvider.notifier,
      );
      await appStartupOrchestrator.initializeCriticalState();

      container.read(authSecurityBootstrapperProvider).configure(
        initialTokens: bootstrapData.initialAuthTokens,
        translateMessage: appLocalizationService.tr,
        showMessage: (String message, {Object? source}) async {
          final NavigatorState? navigatorState = appNavigatorKey.currentState;
          final BuildContext? context = navigatorState?.context;
          if (context == null || !context.mounted) {
            return;
          }

          context.showErrorSnackBar(message, source: source);
        },
      );

      unawaited(appStartupOrchestrator.initializeBackgroundServices());

      return AppBootstrapPayload(
        initialBrightness: Brightness.dark,
        app: UncontrolledProviderScope(
          container: container,
          child: const GlobalAirsoftApp(),
        ),
      );
    },
  );
}

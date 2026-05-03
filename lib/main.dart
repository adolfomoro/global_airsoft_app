import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/app/app_bootstrap.dart';
import 'package:global_airsoft_app/src/app/app_navigator.dart';
import 'package:global_airsoft_app/src/app/app_providers.dart';
import 'package:global_airsoft_app/src/app/global_airsoft_app.dart';
import 'package:global_airsoft_app/src/app/services/app_startup_service.dart';
import 'package:global_airsoft_app/src/core/config/app_config.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_providers.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_service.dart';
import 'package:global_airsoft_app/src/core/localization/app_localization_service.dart';
import 'package:global_airsoft_app/src/core/logging/app_logger.dart';
import 'package:global_airsoft_app/src/core/monitoring/app_telemetry.dart';
import 'package:global_airsoft_app/src/core/network/app_dio_service.dart';
import 'package:global_airsoft_app/src/core/notifications/notification_permission_service.dart';
import 'package:global_airsoft_app/src/core/notifications/push_notification_service.dart';
import 'package:global_airsoft_app/src/core/storage/secure_storage_service.dart';
import 'package:global_airsoft_app/src/core/storage/secure_storage_service_impl.dart';
import 'package:global_airsoft_app/src/core/storage/storage_providers.dart';
import 'package:global_airsoft_app/src/core/widgets/app_snack_bar_presenter.dart';
import 'package:global_airsoft_app/src/features/auth/application/services/auth_security_coordinator.dart';
import 'package:global_airsoft_app/src/features/auth/application/services/auth_storage_service.dart';
import 'package:global_airsoft_app/src/features/auth/application/services/auth_token_refresh_service.dart';
import 'package:global_airsoft_app/src/features/auth/domain/models/auth_tokens.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:global_airsoft_app/src/features/device/application/services/device_registration_service.dart';

Future<void> main() async {
  final AppConfig appConfig = AppConfig.fromDartDefines();
  await AppTelemetry.instance.initialize(appConfig);

  await bootstrapApp(
    builder: () async {
      PushNotificationService.registerBackgroundHandler();

      final SecureStorageService secureStorageService =
          SecureStorageServiceImpl.create();
      final SharedPrefsKeyValueStore keyValueStore =
          await SharedPrefsKeyValueStore.create();
      final AppLocaleService appLocaleService = AppLocaleService(
        store: keyValueStore,
      );
      final AppLocaleBootstrapData localeBootstrapData = await appLocaleService
          .initializeFromDevice();
      final NotificationPermissionService notificationPermissionService =
          NotificationPermissionService(store: keyValueStore);
      final AuthStorageService authStorageService = AuthStorageService(
        secureStorage: secureStorageService,
      );
      await notificationPermissionService.markAppOpened();
      final AuthTokens? tokens = await authStorageService.getTokens();
      final bool isAuthenticated = tokens != null && tokens.jwtToken.isNotEmpty;

      late final ProviderContainer container;
      final AppLocalizationService appLocalizationService =
          AppLocalizationService(
            localeResolver: () => container.read(appLocaleControllerProvider),
          );
      container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(appConfig),
          secureStorageServiceProvider.overrideWithValue(secureStorageService),
          sharedPrefsKeyValueStoreProvider.overrideWithValue(keyValueStore),
          appLocaleServiceProvider.overrideWithValue(appLocaleService),
          initialAppLocaleProvider.overrideWithValue(
            localeBootstrapData.initialUiLocale,
          ),
          initialOsLanguageTagProvider.overrideWithValue(
            localeBootstrapData.osLanguageTag,
          ),
          appLocalizationServiceProvider.overrideWithValue(
            appLocalizationService,
          ),
          authStorageServiceProvider.overrideWithValue(authStorageService),
          initialIsAuthenticatedProvider.overrideWithValue(isAuthenticated),
        ],
      );

      final DeviceRegistrationService deviceRegistrationService = container.read(
        deviceRegistrationServiceProvider,
      );
      final AppStartupService appStartupService = AppStartupService(
        deviceRegistrationService: deviceRegistrationService,
        pushNotificationService: container.read(pushNotificationServiceProvider),
        onPushTokenReceived: (String token) {
          container.read(pushTokenProvider.notifier).setToken(token);
        },
        logger: AppLogger.instance,
      );
      await appStartupService.initializeCriticalState();
      final AppDioService refreshDioService = AppDioService.create(
        config: appConfig,
        logger: AppLogger.instance,
        getDeviceId: () {
          return deviceRegistrationService.getStoredDeviceId();
        },
        ensureDeviceSynced: () {
          return deviceRegistrationService.ensureRegisteredBeforeRequest();
        },
        getDeviceLanguage: () {
          return container.read(appOsLanguageTagProvider);
        },
        onContentLanguage: container
            .read(appLocaleControllerProvider.notifier)
            .syncFromServerContentLanguage,
        apiExceptionMessagesResolver: () {
          return buildLocalizedApiExceptionMessages(appLocalizationService);
        },
        deviceSyncRequiredMessageResolver: () {
          return appLocalizationService.tr(
            AppLocaleKeys.commonGenericApiErrorMessage,
          );
        },
      );
      final AuthTokenRefreshService authTokenRefreshService =
          AuthTokenRefreshService(dioService: refreshDioService);

      AuthSecurityCoordinator.instance.configure(
        getTokens: authStorageService.getTokens,
        saveTokens: authStorageService.saveTokens,
        initialTokens: tokens,
        cacheInitialTokens: true,
        clearSession: () async {
          await authStorageService.clearAll();
          await keyValueStore.remove('user_id_for_backup');
          container.read(isAuthenticatedProvider.notifier).setUnauthenticated();
        },
        refreshTokens: authTokenRefreshService.refreshTokens,
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

      unawaited(appStartupService.initializeBackgroundServices());

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

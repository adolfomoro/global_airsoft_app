import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/app/app_providers.dart';
import 'package:global_airsoft_app/src/app/bootstrap/app_bootstrap_providers.dart';
import 'package:global_airsoft_app/src/core/config/app_config.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_providers.dart';
import 'package:global_airsoft_app/src/core/localization/app_localization_service.dart';
import 'package:global_airsoft_app/src/core/logging/app_logger.dart';
import 'package:global_airsoft_app/src/core/network/app_dio_service.dart';
import 'package:global_airsoft_app/src/core/storage/key_value_store.dart';
import 'package:global_airsoft_app/src/core/storage/storage_providers.dart';
import 'package:global_airsoft_app/src/features/auth/application/providers/auth_security_providers.dart';
import 'package:global_airsoft_app/src/features/auth/application/services/auth_security_bootstrapper.dart';
import 'package:global_airsoft_app/src/features/auth/application/services/auth_service.dart';
import 'package:global_airsoft_app/src/features/auth/application/services/auth_storage_service.dart';
import 'package:global_airsoft_app/src/features/auth/application/services/auth_token_refresh_service.dart';
import 'package:global_airsoft_app/src/features/auth/application/services/google_sign_in_service.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/auth_repository.dart';
import 'package:global_airsoft_app/src/features/device/application/services/device_registration_service.dart';

final Provider<AuthStorageService> authStorageServiceProvider =
    Provider<AuthStorageService>((Ref ref) {
      final bootstrapData = ref.watch(appBootstrapDataProvider);
      return bootstrapData.authStorageService;
    });

final Provider<AppDioService> authRefreshDioServiceProvider =
    Provider<AppDioService>((Ref ref) {
      final AppConfig appConfig = ref.watch(appConfigProvider);
      final AppLocalizationService appLocalizationService = ref.watch(
        appLocalizationServiceProvider,
      );
      final DeviceRegistrationService deviceRegistrationService = ref.watch(
        deviceRegistrationServiceProvider,
      );

      return AppDioService.create(
        config: appConfig,
        logger: AppLogger.instance,
        getDeviceId: () {
          return deviceRegistrationService.getStoredDeviceId();
        },
        ensureDeviceSynced: () {
          return deviceRegistrationService.ensureRegisteredBeforeRequest();
        },
        getDeviceLanguage: () {
          return ref.read(appOsLanguageTagProvider);
        },
        onContentLanguage: ref
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
    });

final Provider<AuthTokenRefreshService> authTokenRefreshServiceProvider =
    Provider<AuthTokenRefreshService>((Ref ref) {
      return AuthTokenRefreshService(
        dioService: ref.watch(authRefreshDioServiceProvider),
      );
    });

final Provider<AuthSecurityBootstrapper> authSecurityBootstrapperProvider =
    Provider<AuthSecurityBootstrapper>((Ref ref) {
      return AuthSecurityBootstrapper(
        coordinator: ref.watch(authSecurityCoordinatorProvider),
        authStorageService: ref.watch(authStorageServiceProvider),
        refreshTokens: ref.watch(authTokenRefreshServiceProvider).refreshTokens,
        keyValueStore: ref.watch(keyValueStoreProvider),
        clearLocalSessionData: ref.watch(authLocalSessionCleanupProvider),
        setUnauthenticated: () {
          ref.read(isAuthenticatedProvider.notifier).setUnauthenticated();
        },
      );
    });

final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>((Ref ref) {
      final appDioService = ref.watch(appDioServiceProvider);
      final localizationService = ref.watch(appLocalizationServiceProvider);
      return AuthRepository(
        dioService: appDioService,
        localizationService: localizationService,
      );
    });

final Provider<AuthService> authServiceProvider = Provider<AuthService>((
  Ref ref,
) {
  final authRepository = ref.watch(authRepositoryProvider);
  final authStorageService = ref.watch(authStorageServiceProvider);
  final authSecurityCoordinator = ref.watch(authSecurityCoordinatorProvider);
  final sharedPrefs = ref.watch(sharedPrefsKeyValueStoreProvider);
  final clearLocalSessionData = ref.watch(authLocalSessionCleanupProvider);
  return AuthService(
    authRepository: authRepository,
    authStorageService: authStorageService,
    authSecurityCoordinator: authSecurityCoordinator,
    sharedPrefs: sharedPrefs,
    clearLocalSessionData: clearLocalSessionData,
    logger: AppLogger.instance,
  );
});

final Provider<GoogleSignInService> googleSignInServiceProvider =
    Provider<GoogleSignInService>((Ref ref) {
      final AppConfig config = ref.watch(appConfigProvider);
      return GoogleSignInService(
        serverClientId: config.googleSignInServerClientId,
      );
    });

final Provider<bool> initialIsAuthenticatedProvider = Provider<bool>(
  (Ref ref) {
    final bootstrapData = ref.watch(appBootstrapDataProvider);
    return bootstrapData.isAuthenticated;
  },
);

final NotifierProvider<AuthSessionNotifier, bool> isAuthenticatedProvider =
    NotifierProvider<AuthSessionNotifier, bool>(AuthSessionNotifier.new);

final class AuthSessionNotifier extends Notifier<bool> {
  @override
  bool build() {
    return ref.watch(initialIsAuthenticatedProvider);
  }

  void setAuthenticated() {
    state = true;
  }

  void setUnauthenticated() {
    state = false;
  }
}

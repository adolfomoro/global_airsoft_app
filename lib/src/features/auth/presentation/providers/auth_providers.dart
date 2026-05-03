import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/app/app_providers.dart';
import 'package:global_airsoft_app/src/core/config/app_config.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_providers.dart';
import 'package:global_airsoft_app/src/core/logging/app_logger.dart';
import 'package:global_airsoft_app/src/core/storage/storage_providers.dart';
import 'package:global_airsoft_app/src/features/auth/application/services/auth_service.dart';
import 'package:global_airsoft_app/src/features/auth/application/services/auth_storage_service.dart';
import 'package:global_airsoft_app/src/features/auth/application/services/google_sign_in_service.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/auth_repository.dart';

final Provider<Future<void> Function()> authLocalSessionCleanupProvider =
    Provider<Future<void> Function()>((Ref ref) => () async {});

final Provider<AuthStorageService> authStorageServiceProvider =
    Provider<AuthStorageService>((Ref ref) {
      final secureStorage = ref.watch(secureStorageServiceProvider);
      return AuthStorageService(secureStorage: secureStorage);
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
  final sharedPrefs = ref.watch(sharedPrefsKeyValueStoreProvider);
  final clearLocalSessionData = ref.watch(authLocalSessionCleanupProvider);
  return AuthService(
    authRepository: authRepository,
    authStorageService: authStorageService,
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
  (Ref ref) => false,
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

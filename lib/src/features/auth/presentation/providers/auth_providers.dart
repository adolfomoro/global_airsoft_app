import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/app/app_providers.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_providers.dart';
import 'package:global_airsoft_app/src/core/logging/app_logger.dart';
import 'package:global_airsoft_app/src/core/storage/storage_providers.dart';
import 'package:global_airsoft_app/src/features/auth/application/services/auth_service.dart';
import 'package:global_airsoft_app/src/features/auth/application/services/auth_storage_service.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/dto/password_validation_rules_output_dto.dart';

const int _maxPasswordRulesFetchAttempts = 3;

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
  return AuthService(
    authRepository: authRepository,
    authStorageService: authStorageService,
    sharedPrefs: sharedPrefs,
    logger: AppLogger.instance,
  );
});

final NotifierProvider<
  PasswordValidationRulesNotifier,
  AsyncValue<PasswordValidationRulesOutputDto?>
>
passwordValidationRulesProvider =
    NotifierProvider<
      PasswordValidationRulesNotifier,
      AsyncValue<PasswordValidationRulesOutputDto?>
    >(PasswordValidationRulesNotifier.new);

final class PasswordValidationRulesNotifier
    extends Notifier<AsyncValue<PasswordValidationRulesOutputDto?>> {
  int _failureCount = 0;

  @override
  AsyncValue<PasswordValidationRulesOutputDto?> build() {
    return const AsyncValue<PasswordValidationRulesOutputDto?>.data(null);
  }

  Future<void> fetchInBackground() async {
    final bool hasRules = state.asData?.value != null;
    if (hasRules || state.isLoading) {
      return;
    }

    if (_failureCount >= _maxPasswordRulesFetchAttempts) {
      return;
    }

    state = const AsyncValue<PasswordValidationRulesOutputDto?>.loading();

    final AuthService authService = ref.read(authServiceProvider);
    try {
      final PasswordValidationRulesOutputDto rules = await authService
          .getPasswordValidationRules();
      _failureCount = 0;
      state = AsyncValue<PasswordValidationRulesOutputDto?>.data(rules);
    } catch (_) {
      _failureCount = _failureCount + 1;
      state = const AsyncValue<PasswordValidationRulesOutputDto?>.data(null);
    }
  }
}

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

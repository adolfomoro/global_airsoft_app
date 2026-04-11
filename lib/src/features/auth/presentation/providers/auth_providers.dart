import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/app/app_providers.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_providers.dart';
import 'package:global_airsoft_app/src/core/logging/app_logger.dart';
import 'package:global_airsoft_app/src/core/storage/storage_providers.dart';
import 'package:global_airsoft_app/src/features/auth/application/services/auth_service.dart';
import 'package:global_airsoft_app/src/features/auth/application/services/auth_storage_service.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository.dart';

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
  return AuthService(
    authRepository: authRepository,
    authStorageService: authStorageService,
    logger: AppLogger.instance,
  );
});

final Provider<bool> isAuthenticatedProvider = Provider<bool>(
  (Ref ref) => false,
);

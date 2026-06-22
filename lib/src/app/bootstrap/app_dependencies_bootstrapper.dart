import 'package:global_airsoft_app/src/core/localization/app_locale_service.dart';
import 'package:global_airsoft_app/src/core/notifications/notification_permission_service.dart';
import 'package:global_airsoft_app/src/core/storage/key_value_store.dart';
import 'package:global_airsoft_app/src/core/storage/secure_storage_service.dart';
import 'package:global_airsoft_app/src/core/storage/secure_storage_service_impl.dart';
import 'package:global_airsoft_app/src/core/storage/shared_prefs_key_value_store.dart';
import 'package:global_airsoft_app/src/features/auth/application/services/auth_storage_service.dart';
import 'package:global_airsoft_app/src/features/auth/domain/models/auth_tokens.dart';

final class AppDependenciesBootstrapData {
  const AppDependenciesBootstrapData({
    required this.secureStorageService,
    required this.keyValueStore,
    required this.appLocaleService,
    required this.localeBootstrapData,
    required this.authStorageService,
    required this.initialAuthTokens,
    required this.isAuthenticated,
  });

  final SecureStorageService secureStorageService;
  final KeyValueStore keyValueStore;
  final AppLocaleService appLocaleService;
  final AppLocaleBootstrapData localeBootstrapData;
  final AuthStorageService authStorageService;
  final AuthTokens? initialAuthTokens;
  final bool isAuthenticated;
}

final class AppDependenciesBootstrapper {
  static Future<AppDependenciesBootstrapData> bootstrap() async {
    final SecureStorageService secureStorageService =
        SecureStorageServiceImpl.create();
    final KeyValueStore keyValueStore =
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
    final AuthTokens? initialAuthTokens = await authStorageService.getTokens();
    final bool isAuthenticated =
        initialAuthTokens != null && initialAuthTokens.jwtToken.isNotEmpty;

    return AppDependenciesBootstrapData(
      secureStorageService: secureStorageService,
      keyValueStore: keyValueStore,
      appLocaleService: appLocaleService,
      localeBootstrapData: localeBootstrapData,
      authStorageService: authStorageService,
      initialAuthTokens: initialAuthTokens,
      isAuthenticated: isAuthenticated,
    );
  }
}

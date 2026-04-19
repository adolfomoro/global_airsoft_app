import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/core/config/app_config.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_providers.dart';
import 'package:global_airsoft_app/src/core/localization/app_localization_service.dart';
import 'package:global_airsoft_app/src/core/logging/app_logger.dart';
import 'package:global_airsoft_app/src/core/network/app_dio_service.dart';
import 'package:global_airsoft_app/src/core/notifications/notification_permission_service.dart';
import 'package:global_airsoft_app/src/core/notifications/push_notification_service.dart';
import 'package:global_airsoft_app/src/core/storage/storage_providers.dart';
import 'package:global_airsoft_app/src/features/device/application/services/device_registration_service.dart';
import 'package:global_airsoft_app/src/features/device/application/services/device_storage_service.dart';
import 'package:global_airsoft_app/src/features/device/data/constants/device_api_paths.dart';
import 'package:global_airsoft_app/src/features/device/data/repositories/device_repository/device_repository.dart';

final NotifierProvider<PushTokenNotifier, String> pushTokenProvider =
    NotifierProvider<PushTokenNotifier, String>(PushTokenNotifier.new);

final Provider<PushNotificationService> pushNotificationServiceProvider =
    Provider<PushNotificationService>((Ref ref) {
      final AppLocalizationService localizationService = ref.watch(
        appLocalizationServiceProvider,
      );
      return PushNotificationService(
        logger: AppLogger.instance,
        localizationService: localizationService,
      );
    });

final Provider<NotificationPermissionService>
notificationPermissionServiceProvider = Provider<NotificationPermissionService>(
  (Ref ref) {
    final sharedPrefsKeyValueStore = ref.watch(
      sharedPrefsKeyValueStoreProvider,
    );

    return NotificationPermissionService(store: sharedPrefsKeyValueStore);
  },
);

final Provider<DeviceStorageService> deviceStorageServiceProvider =
    Provider<DeviceStorageService>((Ref ref) {
      final secureStorage = ref.watch(secureStorageServiceProvider);

      return DeviceStorageService(secureStorage: secureStorage);
    });

final Provider<DeviceRepository> deviceRepositoryProvider =
    Provider<DeviceRepository>((Ref ref) {
      final Dio dio = ref.watch(appDioClientProvider);
      final AppLocalizationService localizationService = ref.watch(
        appLocalizationServiceProvider,
      );
      return DeviceRepository(
        dio: dio,
        localizationService: localizationService,
      );
    });

final Provider<DeviceRegistrationService> deviceRegistrationServiceProvider =
    Provider<DeviceRegistrationService>((Ref ref) {
      final deviceRepository = ref.watch(deviceRepositoryProvider);
      final storageService = ref.watch(deviceStorageServiceProvider);

      final DeviceRegistrationService service = DeviceRegistrationService(
        deviceRepository: deviceRepository,
        storageService: storageService,
        getPushNotificationToken: () => ref.read(pushTokenProvider),
        logger: AppLogger.instance,
      );
      return service;
    });

final Provider<AppConfig> appConfigProvider = Provider<AppConfig>(
  (Ref ref) => AppConfig.fromDartDefines(),
);

final Provider<AppDioService> appDioServiceProvider = Provider<AppDioService>((
  Ref ref,
) {
  final AppConfig config = ref.watch(appConfigProvider);
  final String osLanguageTag = ref.watch(appOsLanguageTagProvider);
  final localeController = ref.watch(appLocaleControllerProvider.notifier);
  return AppDioService.create(
    config: config,
    logger: AppLogger.instance,
    getDeviceId: () {
      return ref.read(deviceRegistrationServiceProvider).getStoredDeviceId();
    },
    ensureDeviceSynced: () {
      return ref
          .read(deviceRegistrationServiceProvider)
          .ensureRegisteredBeforeRequest();
    },
    getDeviceLanguage: () {
      return osLanguageTag;
    },
    onContentLanguage: localeController.syncFromServerContentLanguage,
    deviceSyncSkipPaths: const <String>{DeviceApiPaths.registerDevice},
  );
});

final Provider<Dio> appDioClientProvider = Provider<Dio>(
  (Ref ref) => ref.watch(appDioServiceProvider).client,
);

final class PushTokenNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setToken(String token) {
    state = token;
  }
}

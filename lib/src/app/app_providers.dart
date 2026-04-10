import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/core/config/app_config.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_providers.dart';
import 'package:global_airsoft_app/src/core/logging/app_logger.dart';
import 'package:global_airsoft_app/src/core/network/app_dio_service.dart';
import 'package:global_airsoft_app/src/core/storage/storage_providers.dart';
import 'package:global_airsoft_app/src/features/device/application/services/device_registration_service.dart';
import 'package:global_airsoft_app/src/features/device/application/services/device_storage_service.dart';
import 'package:global_airsoft_app/src/features/device/data/constants/device_api_paths.dart';
import 'package:global_airsoft_app/src/features/device/data/repositories/device_repository.dart';

final NotifierProvider<PushTokenNotifier, String> pushTokenProvider =
    NotifierProvider<PushTokenNotifier, String>(PushTokenNotifier.new);

final Provider<DeviceRegistrationRuntime> deviceRegistrationRuntimeProvider =
    Provider<DeviceRegistrationRuntime>((Ref ref) {
      return DeviceRegistrationRuntime();
    });

final Provider<DeviceStorageService> deviceStorageServiceProvider =
    Provider<DeviceStorageService>((Ref ref) {
      final secureStorage = ref.watch(secureStorageServiceProvider);

      return DeviceStorageService(secureStorage: secureStorage);
    });

final Provider<DeviceRepository> deviceRepositoryProvider =
    Provider<DeviceRepository>((Ref ref) {
      final Dio dio = ref.watch(appDioClientProvider);
      return DeviceRepository(dio: dio);
    });

final Provider<DeviceRegistrationService> deviceRegistrationServiceProvider =
    Provider<DeviceRegistrationService>((Ref ref) {
      final deviceRepository = ref.watch(deviceRepositoryProvider);
      final storageService = ref.watch(deviceStorageServiceProvider);
      final DeviceRegistrationRuntime runtime = ref.watch(
        deviceRegistrationRuntimeProvider,
      );

      final DeviceRegistrationService service = DeviceRegistrationService(
        deviceRepository: deviceRepository,
        storageService: storageService,
        getPushNotificationToken: () => ref.read(pushTokenProvider),
        logger: AppLogger.instance,
      );

      runtime.attach(service);
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
  final DeviceRegistrationRuntime runtime = ref.watch(
    deviceRegistrationRuntimeProvider,
  );
  final localeController = ref.watch(appLocaleControllerProvider.notifier);
  return AppDioService.create(
    config: config,
    logger: AppLogger.instance,
    getDeviceId: () {
      return runtime.getStoredDeviceId();
    },
    ensureDeviceSynced: () {
      return runtime.ensureDeviceSynced();
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
  String build() => '-teste-';

  void setToken(String token) {
    state = token;
  }
}

final class DeviceRegistrationRuntime {
  DeviceRegistrationService? _service;

  void attach(DeviceRegistrationService service) {
    _service = service;
  }

  String? getStoredDeviceId() {
    return _service?.getStoredDeviceId();
  }

  Future<bool> ensureDeviceSynced() {
    final DeviceRegistrationService? service = _service;
    if (service == null) {
      return Future<bool>.value(true);
    }

    return service.ensureRegisteredBeforeRequest();
  }
}

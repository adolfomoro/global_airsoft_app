import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/core/config/app_config.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_providers.dart';
import 'package:global_airsoft_app/src/core/localization/app_localization_service.dart';
import 'package:global_airsoft_app/src/core/logging/app_logger.dart';
import 'package:global_airsoft_app/src/core/network/app_dio_service.dart';
import 'package:global_airsoft_app/src/core/network/app_http_client_factory.dart';
import 'package:global_airsoft_app/src/core/network/constants/app_network_headers.dart';
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
      final Dio dio = ref.watch(deviceApiDioClientProvider);
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

AppDioService _buildAppDioService(
  Ref ref, {
  String? Function()? getDeviceId,
  Future<bool> Function()? ensureDeviceSynced,
  Set<String> deviceSyncSkipPaths = const <String>{},
  bool enableAuthSecurityInterceptor = false,
}) {
  final AppConfig config = ref.watch(appConfigProvider);
  final String osLanguageTag = ref.watch(appOsLanguageTagProvider);
  final AppLocalizationService localizationService = ref.watch(
    appLocalizationServiceProvider,
  );
  final localeController = ref.watch(appLocaleControllerProvider.notifier);

  return AppDioService.create(
    config: config,
    logger: AppLogger.instance,
    getDeviceId: getDeviceId,
    ensureDeviceSynced: ensureDeviceSynced,
    getDeviceLanguage: () {
      return osLanguageTag;
    },
    onContentLanguage: localeController.syncFromServerContentLanguage,
    apiExceptionMessagesResolver: () {
      return buildLocalizedApiExceptionMessages(localizationService);
    },
    deviceSyncRequiredMessageResolver: () {
      return localizationService.tr(AppLocaleKeys.commonGenericApiErrorMessage);
    },
    deviceSyncSkipPaths: deviceSyncSkipPaths,
    enableAuthSecurityInterceptor: enableAuthSecurityInterceptor,
  );
}

final Provider<AppDioService> appDioServiceProvider = Provider<AppDioService>((
  Ref ref,
) {
  return _buildAppDioService(
    ref,
    getDeviceId: () {
      return ref.read(deviceRegistrationServiceProvider).getStoredDeviceId();
    },
    ensureDeviceSynced: () {
      return ref
          .read(deviceRegistrationServiceProvider)
          .ensureRegisteredBeforeRequest();
    },
    deviceSyncSkipPaths: const <String>{DeviceApiPaths.registerDevice},
    enableAuthSecurityInterceptor: true,
  );
});

final Provider<AppDioService> deviceApiDioServiceProvider =
    Provider<AppDioService>((Ref ref) {
      return _buildAppDioService(ref);
    });

final Provider<Dio> appDioClientProvider = Provider<Dio>(
  (Ref ref) => ref.watch(appDioServiceProvider).client,
);

final Provider<Dio> deviceApiDioClientProvider = Provider<Dio>(
  (Ref ref) => ref.watch(deviceApiDioServiceProvider).client,
);

final Provider<Dio> externalDioClientProvider = Provider<Dio>((Ref ref) {
  final AppConfig config = ref.watch(appConfigProvider);
  final Dio dio = Dio(
    BaseOptions(
      connectTimeout: Duration(milliseconds: config.connectTimeoutMs),
      receiveTimeout: Duration(milliseconds: config.receiveTimeoutMs),
      sendTimeout: Duration(milliseconds: config.sendTimeoutMs),
      headers: <String, Object>{
        AppNetworkHeaders.userAgentHeader: AppNetworkHeaders.userAgentValue,
      },
    ),
  );

  if (config.environment == AppEnvironment.dev) {
    final HttpClientAdapter adapter = dio.httpClientAdapter;
    if (adapter is IOHttpClientAdapter) {
      adapter.createHttpClient = () {
        return AppHttpClientFactory.create(
          allowBadCertificates: true,
          onBadCertificateAccepted: (String host, int port) {
            AppLogger.instance.debug(
              'TLS certificate validation disabled for external HTTP DEV environment: $host:$port',
            );
          },
        );
      };
    }
  }

  return dio;
});

final class PushTokenNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setToken(String token) {
    state = token;
  }
}

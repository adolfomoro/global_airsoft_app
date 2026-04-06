import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../network/dio_service.dart';
import '../services/device_service.dart';
import '../services/device_storage_service.dart';
import '../services/fcm_push_token_service.dart';
import '../services/preferences_service.dart';
import '../services/notification_permission_service.dart';
import 'device_id_notifier.dart';
import 'push_token_notifier.dart';
import '../../features/device/data/constants/device_api_paths.dart';
import '../../features/device/data/repositories/device_repository.dart';

StreamSubscription<String>? _pushTokenSubscription;

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((
  ref,
) async {
  return SharedPreferences.getInstance();
});

  final notificationPermissionServiceProvider = FutureProvider<NotificationPermissionService>((
    ref,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    return NotificationPermissionService(prefs);
  });

final preferencesServiceProvider = FutureProvider<PreferencesService>((
  ref,
) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return PreferencesService(prefs: prefs);
});

final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.current;
});

final dioServiceProvider = Provider<DioService>((ref) {
  final config = ref.watch(appConfigProvider);
  return DioService(
    config: config,
    getDeviceId: () => ref.read(deviceIdNotifierProvider),
    ensureDeviceSynced: () async {
      final deviceService = await ref.read(deviceServiceProvider.future);
      final didSync = await deviceService.ensureRegisteredBeforeRequest();

      final deviceId = deviceService.getStoredDeviceId();
      if (deviceId != null && deviceId.isNotEmpty) {
        ref.read(deviceIdNotifierProvider.notifier).setDeviceId(deviceId);
      }

      return didSync;
    },
    skipDeviceSyncPaths: const {DeviceApiPaths.registerDevice},
  );
});

final dioProvider = Provider<Dio>((ref) {
  return ref.watch(dioServiceProvider).client;
});

final deviceStorageServiceProvider = FutureProvider<DeviceStorageService>((
  ref,
) async {
  final prefsService = await ref.watch(preferencesServiceProvider.future);
  return DeviceStorageService(preferencesService: prefsService);
});

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return DeviceRepository(dio: dio);
});

final deviceServiceProvider = FutureProvider<DeviceService>((ref) async {
  final storageService = await ref.watch(deviceStorageServiceProvider.future);
  final deviceRepository = ref.watch(deviceRepositoryProvider);

  return DeviceService(
    deviceRepository: deviceRepository,
    storageService: storageService,
    getPushNotificationToken: () => ref.read(pushTokenNotifierProvider),
  );
});

final fcmPushTokenServiceProvider = Provider<FcmPushTokenService>((ref) {
  final service = FcmPushTokenService();
  ref.onDispose(() {
    unawaited(service.dispose());
  });
  return service;
});

Future<void> initializePushTokenMonitoring(ProviderContainer container) async {
  final tokenNotifier = container.read(pushTokenNotifierProvider.notifier);
  final tokenService = container.read(fcmPushTokenServiceProvider);

  try {
    await _pushTokenSubscription?.cancel();
  } catch (e) {
    assert(() {
      debugPrint('Push token subscription cancel error: $e');
      return true;
    }());
  } finally {
    _pushTokenSubscription = null;
  }

    final initialToken = await tokenService.initializeTokenWithoutPermission();

  if (initialToken.isNotEmpty) {
    tokenNotifier.setToken(initialToken);
    unawaited(_syncDeviceAfterTokenChange(container));
  }

  _pushTokenSubscription = tokenService.tokenChanges.listen((token) {
    if (token.isEmpty) {
      return;
    }

    final current = container.read(pushTokenNotifierProvider);
    if (current == token) {
      return;
    }

    tokenNotifier.setToken(token);
    unawaited(_syncDeviceAfterTokenChange(container));
  });
}

Future<void> _syncDeviceAfterTokenChange(ProviderContainer container) async {
  try {
    final deviceService = await container.read(deviceServiceProvider.future);
    await deviceService.registerInBackground();

    final newDeviceId = deviceService.getStoredDeviceId();
    if (newDeviceId != null && newDeviceId.isNotEmpty) {
      container.read(deviceIdNotifierProvider.notifier).setDeviceId(newDeviceId);
    }
  } catch (e) {
    assert(() {
      debugPrint('Device update after token change failed: $e');
      return true;
    }());
  }
}

Future<void> initializeDeviceService(ProviderContainer container) async {
  try {
    final deviceService = await container.read(deviceServiceProvider.future);
    final deviceIdNotifier = container.read(deviceIdNotifierProvider.notifier);

    final deviceIdFromStorage = deviceService.initializeSync();
    deviceIdNotifier.setDeviceId(deviceIdFromStorage);
    unawaited(
      () async {
        try {
          await deviceService.registerInBackground();
          if (deviceIdFromStorage.isEmpty) {
            final newDeviceId = deviceService.getStoredDeviceId();
            if (newDeviceId != null && newDeviceId.isNotEmpty) {
              deviceIdNotifier.setDeviceId(newDeviceId);
            }
          }
        } catch (e) {
          assert(() {
            debugPrint('Device registration error: $e');
            return true;
          }());
        }
      }(),
    );
  } catch (e) {
    rethrow;
  }
}

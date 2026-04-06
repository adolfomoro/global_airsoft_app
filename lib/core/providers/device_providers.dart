import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/interceptors/device_id_interceptor.dart';
import '../services/device_service.dart';
import '../services/device_storage_service.dart';
import '../services/preferences_service.dart';
import 'device_id_notifier.dart';
import '../../features/device/data/repositories/device_repository.dart';

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((
  ref,
) async {
  return SharedPreferences.getInstance();
});

final preferencesServiceProvider = FutureProvider<PreferencesService>((
  ref,
) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return PreferencesService(prefs: prefs);
});

final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      responseType: ResponseType.json,
    ),
  );
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
    getPushNotificationToken: () {
      return 'dummy-fcm-token';
    },
  );
});

Future<void> initializeDeviceService(ProviderContainer container) async {
  try {
    final deviceService = await container.read(deviceServiceProvider.future);
    final deviceIdNotifier = container.read(deviceIdNotifierProvider.notifier);
    final dio = container.read(dioProvider);

    final deviceIdFromStorage = deviceService.initializeSync();
    deviceIdNotifier.setDeviceId(deviceIdFromStorage);
    dio.interceptors.add(DeviceIdInterceptor(deviceIdFromStorage));
    deviceService
        .registerInBackground()
        .then((_) {
          if (deviceIdFromStorage.isEmpty) {
            final newDeviceId = deviceService.getStoredDeviceId();
            if (newDeviceId != null && newDeviceId.isNotEmpty) {
              deviceIdNotifier.setDeviceId(newDeviceId);
            }
          }
        })
        .catchError((e) {
          // ignore: avoid_print
          print('Device registration error: $e');
        });
  } catch (e) {
    rethrow;
  }
}

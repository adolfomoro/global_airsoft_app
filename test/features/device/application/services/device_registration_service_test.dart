import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_airsoft_app/src/core/localization/app_localization_service.dart';
import 'package:global_airsoft_app/src/core/logging/app_logger.dart';
import 'package:global_airsoft_app/src/core/storage/secure_storage_service.dart';
import 'package:global_airsoft_app/src/features/device/application/services/device_registration_service.dart';
import 'package:global_airsoft_app/src/features/device/application/services/device_storage_service.dart';
import 'package:global_airsoft_app/src/features/device/data/repositories/device_repository/device_repository.dart';

void main() {
  test(
    'loads stored device id even when push token is still unavailable',
    () async {
      final _CountingSecureStorageService secureStorage =
          _CountingSecureStorageService(
            snapshot: const DeviceStorageSnapshot(
              deviceId: 'device-123',
              lastPlatform: 'Android',
              lastDeviceType: 'pixel',
              lastAppVersion: '1.0.0',
              lastDeviceModel: 'Pixel',
              lastPushToken: 'push-123',
            ),
          );

      final DeviceRegistrationService service = DeviceRegistrationService(
        deviceRepository: DeviceRepository(
          dio: Dio(
            BaseOptions(
              baseUrl: 'http://127.0.0.1:9',
              connectTimeout: const Duration(milliseconds: 10),
              receiveTimeout: const Duration(milliseconds: 10),
              sendTimeout: const Duration(milliseconds: 10),
            ),
          ),
          localizationService: AppLocalizationService(
            locale: const Locale('en'),
          ),
        ),
        storageService: DeviceStorageService(secureStorage: secureStorage),
        getPushNotificationToken: () => '',
        logger: AppLogger.instance,
      );

      final bool synced = await service.ensureRegisteredBeforeRequest();

      await service.registerInBackground();

      expect(synced, isTrue);
      expect(secureStorage.getStringCalls, 1);
      expect(service.getStoredDeviceId(), 'device-123');
    },
  );
}

final class _CountingSecureStorageService implements SecureStorageService {
  _CountingSecureStorageService({this.snapshot});

  int getStringCalls = 0;
  final DeviceStorageSnapshot? snapshot;

  @override
  Future<void> clear() async {}

  @override
  Future<void> remove(String key) async {}

  @override
  Future<String?> getString(String key) async {
    getStringCalls++;
    final DeviceStorageSnapshot? value = snapshot;
    if (value == null) {
      return null;
    }

    return jsonEncode(value.toJson());
  }

  @override
  Future<void> setString(String key, String value) async {}
}

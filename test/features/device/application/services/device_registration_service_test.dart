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
  test('skips device sync until a push token is available', () async {
    final _CountingSecureStorageService secureStorage =
        _CountingSecureStorageService();

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
        localizationService: AppLocalizationService(locale: const Locale('en')),
      ),
      storageService: DeviceStorageService(secureStorage: secureStorage),
      getPushNotificationToken: () => '',
      logger: AppLogger.instance,
    );

    final bool synced = await service.ensureRegisteredBeforeRequest();

    await service.registerInBackground();

    expect(synced, isTrue);
    expect(secureStorage.getStringCalls, 0);
  });
}

final class _CountingSecureStorageService implements SecureStorageService {
  int getStringCalls = 0;

  @override
  Future<void> clear() async {}

  @override
  Future<void> remove(String key) async {}

  @override
  Future<String?> getString(String key) async {
    getStringCalls++;
    return null;
  }

  @override
  Future<void> setString(String key, String value) async {}
}

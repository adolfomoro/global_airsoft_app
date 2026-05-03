import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_airsoft_app/src/core/localization/app_localization_service.dart';
import 'package:global_airsoft_app/src/core/logging/app_logger.dart';
import 'package:global_airsoft_app/src/core/storage/secure_storage_service.dart';
import 'package:global_airsoft_app/src/features/device/application/models/device_storage_snapshot.dart';
import 'package:global_airsoft_app/src/features/device/application/services/device_registration_service.dart';
import 'package:global_airsoft_app/src/features/device/application/services/device_storage_service.dart';
import 'package:global_airsoft_app/src/features/device/data/repositories/device_repository/device_repository.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Global Airsoft',
      packageName: 'com.example.global_airsoft_app',
      version: '2.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  test(
    'loads stored device id even when push token is still unavailable',
    () async {
      final _CountingSecureStorageService secureStorage =
          _CountingSecureStorageService(
            snapshot: const DeviceStorageSnapshot(
              deviceId: 'device-123',
              lastPlatform: 'Unknown',
              lastDeviceType: 'Unknown',
              lastAppVersion: '2.0.0',
              lastDeviceModel: null,
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

  test(
    'registers a new device without sending an empty push token',
    () async {
      final _RecordingHttpClientAdapter adapter = _RecordingHttpClientAdapter();
      final _CountingSecureStorageService secureStorage =
          _CountingSecureStorageService();

      final DeviceRegistrationService service = DeviceRegistrationService(
        deviceRepository: DeviceRepository(
          dio: Dio(BaseOptions(baseUrl: 'https://api.example.com'))
            ..httpClientAdapter = adapter,
          localizationService: AppLocalizationService(
            locale: const Locale('en'),
          ),
        ),
        storageService: DeviceStorageService(secureStorage: secureStorage),
        getPushNotificationToken: () => '',
        logger: AppLogger.instance,
      );

      final bool synced = await service.ensureRegisteredBeforeRequest();
      final Map<String, dynamic> requestBody =
          adapter.lastRequestBody! as Map<String, dynamic>;

      expect(synced, isTrue);
      expect(requestBody.containsKey('pushNotificationToken'), isFalse);
      expect(secureStorage.lastSavedSnapshot?.lastPushToken, isNull);
      expect(service.getStoredDeviceId(), 'device-123');
    },
  );

  test(
    'preserves the last known push token when the current token is unavailable',
    () async {
      final _RecordingHttpClientAdapter adapter = _RecordingHttpClientAdapter();
      final _CountingSecureStorageService secureStorage =
          _CountingSecureStorageService(
            snapshot: const DeviceStorageSnapshot(
              deviceId: 'device-123',
              lastPlatform: 'Unknown',
              lastDeviceType: 'Unknown',
              lastAppVersion: '1.0.0',
              lastDeviceModel: null,
              lastPushToken: 'push-123',
            ),
          );

      final DeviceRegistrationService service = DeviceRegistrationService(
        deviceRepository: DeviceRepository(
          dio: Dio(BaseOptions(baseUrl: 'https://api.example.com'))
            ..httpClientAdapter = adapter,
          localizationService: AppLocalizationService(
            locale: const Locale('en'),
          ),
        ),
        storageService: DeviceStorageService(secureStorage: secureStorage),
        getPushNotificationToken: () => '',
        logger: AppLogger.instance,
      );

      final bool synced = await service.ensureRegisteredBeforeRequest();
      final Map<String, dynamic> requestBody =
          adapter.lastRequestBody! as Map<String, dynamic>;

      expect(synced, isTrue);
      expect(requestBody['pushNotificationToken'], 'push-123');
      expect(secureStorage.lastSavedSnapshot?.lastPushToken, 'push-123');
      expect(service.getStoredDeviceId(), 'device-123');
    },
  );
}

final class _CountingSecureStorageService implements SecureStorageService {
  _CountingSecureStorageService({this.snapshot});

  int getStringCalls = 0;
  final DeviceStorageSnapshot? snapshot;
  DeviceStorageSnapshot? lastSavedSnapshot;

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
  Future<void> setString(String key, String value) async {
    final Object? decoded = jsonDecode(value);
    if (decoded is Map<String, dynamic>) {
      lastSavedSnapshot = DeviceStorageSnapshot.fromJson(decoded);
    }
  }
}

final class _RecordingHttpClientAdapter implements HttpClientAdapter {
  Object? lastRequestBody;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequestBody = options.data;
    await requestStream?.drain<void>();

    return ResponseBody.fromString(
      '{"deviceId":"device-123"}',
      HttpStatus.ok,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

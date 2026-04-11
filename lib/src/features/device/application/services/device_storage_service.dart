import 'dart:convert';

import 'package:global_airsoft_app/src/core/storage/secure_storage_service.dart';

final class DeviceStorageService {
  DeviceStorageService({required SecureStorageService secureStorage})
    : _secureStorage = secureStorage;

  static const String _storageKey = 'device_registration_entity';

  final SecureStorageService _secureStorage;

  Future<DeviceStorageSnapshot> loadSnapshot() async {
    final String? raw = await _secureStorage.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return DeviceStorageSnapshot.empty();
    }

    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return DeviceStorageSnapshot.empty();
      }

      return DeviceStorageSnapshot.fromJson(decoded);
    } catch (_) {
      return DeviceStorageSnapshot.empty();
    }
  }

  Future<void> saveSnapshot(DeviceStorageSnapshot snapshot) {
    final String payload = jsonEncode(snapshot.toJson());
    return _secureStorage.setString(_storageKey, payload);
  }
}

final class DeviceStorageSnapshot {
  const DeviceStorageSnapshot({
    required this.deviceId,
    required this.lastPlatform,
    required this.lastDeviceType,
    required this.lastAppVersion,
    required this.lastDeviceModel,
    required this.lastPushToken,
  });

  const DeviceStorageSnapshot.empty()
    : deviceId = null,
      lastPlatform = null,
      lastDeviceType = null,
      lastAppVersion = null,
      lastDeviceModel = null,
      lastPushToken = null;

  final String? deviceId;
  final String? lastPlatform;
  final String? lastDeviceType;
  final String? lastAppVersion;
  final String? lastDeviceModel;
  final String? lastPushToken;

  factory DeviceStorageSnapshot.fromJson(Map<String, dynamic> json) {
    return DeviceStorageSnapshot(
      deviceId: _readNullableString(json['deviceId']),
      lastPlatform: _readNullableString(json['lastPlatform']),
      lastDeviceType: _readNullableString(json['lastDeviceType']),
      lastAppVersion: _readNullableString(json['lastAppVersion']),
      lastDeviceModel: _readNullableString(json['lastDeviceModel']),
      lastPushToken: _readNullableString(json['lastPushToken']),
    );
  }

  Map<String, String> toJson() {
    final Map<String, String> result = <String, String>{};

    if (deviceId != null && deviceId!.isNotEmpty) {
      result['deviceId'] = deviceId!;
    }
    if (lastPlatform != null && lastPlatform!.isNotEmpty) {
      result['lastPlatform'] = lastPlatform!;
    }
    if (lastDeviceType != null && lastDeviceType!.isNotEmpty) {
      result['lastDeviceType'] = lastDeviceType!;
    }
    if (lastAppVersion != null && lastAppVersion!.isNotEmpty) {
      result['lastAppVersion'] = lastAppVersion!;
    }
    if (lastDeviceModel != null && lastDeviceModel!.isNotEmpty) {
      result['lastDeviceModel'] = lastDeviceModel!;
    }
    if (lastPushToken != null && lastPushToken!.isNotEmpty) {
      result['lastPushToken'] = lastPushToken!;
    }

    return result;
  }

  static String? _readNullableString(Object? value) {
    if (value is! String) {
      return null;
    }

    final String normalized = value.trim();
    if (normalized.isEmpty) {
      return null;
    }
    return normalized;
  }
}

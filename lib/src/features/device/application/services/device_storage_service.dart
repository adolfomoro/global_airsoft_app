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

  Future<String?> getDeviceId() async {
    final DeviceStorageSnapshot snapshot = await loadSnapshot();
    return snapshot.deviceId;
  }

  Future<void> saveDeviceId(String deviceId) async {
    final DeviceStorageSnapshot current = await loadSnapshot();
    await saveSnapshot(current.copyWith(deviceId: deviceId));
  }

  Future<String?> getLastPlatform() async {
    final DeviceStorageSnapshot snapshot = await loadSnapshot();
    return snapshot.lastPlatform;
  }

  Future<void> savePlatform(String platform) async {
    final DeviceStorageSnapshot current = await loadSnapshot();
    await saveSnapshot(current.copyWith(lastPlatform: platform));
  }

  Future<String?> getLastDeviceType() async {
    final DeviceStorageSnapshot snapshot = await loadSnapshot();
    return snapshot.lastDeviceType;
  }

  Future<void> saveDeviceType(String deviceType) async {
    final DeviceStorageSnapshot current = await loadSnapshot();
    await saveSnapshot(current.copyWith(lastDeviceType: deviceType));
  }

  Future<String?> getLastAppVersion() async {
    final DeviceStorageSnapshot snapshot = await loadSnapshot();
    return snapshot.lastAppVersion;
  }

  Future<void> saveAppVersion(String appVersion) async {
    final DeviceStorageSnapshot current = await loadSnapshot();
    await saveSnapshot(current.copyWith(lastAppVersion: appVersion));
  }

  Future<String?> getLastDeviceModel() async {
    final DeviceStorageSnapshot snapshot = await loadSnapshot();
    return snapshot.lastDeviceModel;
  }

  Future<void> saveDeviceModel(String? deviceModel) async {
    final DeviceStorageSnapshot current = await loadSnapshot();
    await saveSnapshot(current.copyWith(lastDeviceModel: deviceModel));
  }

  Future<String?> getLastPushToken() async {
    final DeviceStorageSnapshot snapshot = await loadSnapshot();
    return snapshot.lastPushToken;
  }

  Future<void> savePushToken(String pushToken) async {
    final DeviceStorageSnapshot current = await loadSnapshot();
    await saveSnapshot(current.copyWith(lastPushToken: pushToken));
  }

  Future<void> clearAll() async {
    await _secureStorage.remove(_storageKey);
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

    void putIfNotEmpty(String key, String? value) {
      if (value != null && value.isNotEmpty) {
        result[key] = value;
      }
    }

    putIfNotEmpty('deviceId', deviceId);
    putIfNotEmpty('lastPlatform', lastPlatform);
    putIfNotEmpty('lastDeviceType', lastDeviceType);
    putIfNotEmpty('lastAppVersion', lastAppVersion);
    putIfNotEmpty('lastDeviceModel', lastDeviceModel);
    putIfNotEmpty('lastPushToken', lastPushToken);

    return result;
  }

  DeviceStorageSnapshot copyWith({
    String? deviceId,
    String? lastPlatform,
    String? lastDeviceType,
    String? lastAppVersion,
    String? lastDeviceModel,
    String? lastPushToken,
  }) {
    return DeviceStorageSnapshot(
      deviceId: deviceId ?? this.deviceId,
      lastPlatform: lastPlatform ?? this.lastPlatform,
      lastDeviceType: lastDeviceType ?? this.lastDeviceType,
      lastAppVersion: lastAppVersion ?? this.lastAppVersion,
      lastDeviceModel: lastDeviceModel ?? this.lastDeviceModel,
      lastPushToken: lastPushToken ?? this.lastPushToken,
    );
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

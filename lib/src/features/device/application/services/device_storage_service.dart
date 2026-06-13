import 'dart:convert';

import 'package:global_airsoft_app/src/core/logging/app_logger.dart';
import 'package:global_airsoft_app/src/core/storage/secure_storage_service.dart';
import 'package:global_airsoft_app/src/features/device/application/models/device_storage_snapshot.dart';

export 'package:global_airsoft_app/src/features/device/application/models/device_storage_snapshot.dart';

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
    } catch (error, stackTrace) {
      AppLogger.instance.error(
        'Failed to decode device storage snapshot.',
        error: error,
        stackTrace: stackTrace,
      );
      return DeviceStorageSnapshot.empty();
    }
  }

  Future<void> saveSnapshot(DeviceStorageSnapshot snapshot) {
    final String payload = jsonEncode(snapshot.toJson());
    return _secureStorage.setString(_storageKey, payload);
  }
}

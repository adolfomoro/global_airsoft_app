import 'dart:io' as io;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../features/device/domain/models/push_notification_type.dart';
import '../../features/device/domain/models/register_device_input_dto.dart';
import '../../features/device/data/repositories/device_repository.dart';
import 'device_storage_service.dart';

class DeviceService {
  DeviceService({
    required DeviceRepository deviceRepository,
    required DeviceStorageService storageService,
    required String Function() getPushNotificationToken,
  }) : _deviceRepository = deviceRepository,
       _storageService = storageService,
       _getPushNotificationToken = getPushNotificationToken;

  final DeviceRepository _deviceRepository;
  final DeviceStorageService _storageService;
  final String Function() _getPushNotificationToken;

  String _cachedPlatform = 'Unknown';
  String _cachedDeviceType = 'Unknown';
  String _cachedAppVersion = '0.0.0';
  String? _cachedDeviceModel;
  String? _cachedDeviceId;
  String? _storedDeviceId;
  String? _lastPlatform;
  String? _lastDeviceType;
  String? _lastAppVersion;
  String? _lastDeviceModel;
  String? _lastPushToken;
  bool _infoLoaded = false;
  bool _storageSnapshotLoaded = false;
  Future<bool>? _inFlightSync;

  void _debugLog(String message) {
    assert(() {
      debugPrint(message);
      return true;
    }());
  }

  String initializeSync() {
    _storedDeviceId = _storageService.getDeviceId();
    _cachedDeviceId = _storedDeviceId;
    _loadStorageSnapshotIfNeeded();
    return _storedDeviceId ?? '';
  }

  void _loadStorageSnapshotIfNeeded() {
    if (_storageSnapshotLoaded) {
      return;
    }

    _storedDeviceId ??= _storageService.getDeviceId();
    _lastPlatform = _storageService.getLastPlatform();
    _lastDeviceType = _storageService.getLastDeviceType();
    _lastAppVersion = _storageService.getLastAppVersion();
    _lastDeviceModel = _storageService.getLastDeviceModel();
    _lastPushToken = _storageService.getLastPushToken();
    _storageSnapshotLoaded = true;
  }

  Future<void> _loadDeviceInfo() async {
    if (_infoLoaded) return;

    final packageInfo = await PackageInfo.fromPlatform();
    _cachedAppVersion = packageInfo.version;

    final deviceInfo = DeviceInfoPlugin();
    if (io.Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      _cachedPlatform = 'Android';
      _cachedDeviceType = androidInfo.device;
      _cachedDeviceModel = androidInfo.model;
    } else if (io.Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      _cachedPlatform = 'iOS';
      _cachedDeviceType = iosInfo.utsname.machine;
      _cachedDeviceModel = iosInfo.model;
    } else {
      _cachedPlatform = 'Unknown';
      _cachedDeviceType = 'Unknown';
      _cachedDeviceModel = null;
    }

    _infoLoaded = true;
  }

  Future<void> registerInBackground() async {
    try {
      await ensureRegisteredBeforeRequest();
    } catch (e) {
      _debugLog('Device registration error: $e');
    }
  }

  Future<bool> ensureRegisteredBeforeRequest() async {
    _loadStorageSnapshotIfNeeded();

    while (true) {
      final inFlight = _inFlightSync;
      if (inFlight != null) {
        final inFlightResult = await inFlight;
        if (!inFlightResult) {
          return false;
        }

        if (!_needsRegisterOrUpdate()) {
          return true;
        }

        continue;
      }

      if (!_needsRegisterOrUpdate()) {
        return true;
      }

      final syncFuture = _ensureRegisteredInternal();
      _inFlightSync = syncFuture;

      try {
        final syncResult = await syncFuture;
        if (!syncResult) {
          return false;
        }

        if (!_needsRegisterOrUpdate()) {
          return true;
        }
      } finally {
        if (identical(_inFlightSync, syncFuture)) {
          _inFlightSync = null;
        }
      }
    }
  }

  Future<bool> _ensureRegisteredInternal() async {
    await _loadDeviceInfo();

    if (!_needsRegisterOrUpdate()) {
      return true;
    }

    try {
      await _registerOrUpdateDevice();
      return true;
    } catch (e) {
      _debugLog('Device sync failed: $e');
      return false;
    }
  }

  Future<void> _registerOrUpdateDevice() async {
    final storedDeviceId = _storedDeviceId;
    final pushToken = _getPushNotificationToken();

    if (storedDeviceId == null || _hasDeviceInfoChanged(pushToken)) {
      final input = RegisterDeviceInputDto(
        deviceId: storedDeviceId,
        platform: _cachedPlatform,
        deviceType: _cachedDeviceType,
        appVersion: _cachedAppVersion,
        deviceModel: _cachedDeviceModel,
        pushNotificationToken: pushToken,
        pushNotificationType: _getPushNotificationType(),
      );

      final output = await _deviceRepository.registerDevice(input);

      await _storageService.saveDeviceId(output.deviceId);

      await _saveCurrentValuesAsLastKnown(pushToken);

      _storedDeviceId = output.deviceId;
      _cachedDeviceId = output.deviceId;

      _debugLog('Device registered: ${output.deviceId}');
    }
  }

  bool _needsRegisterOrUpdate() {
    final pushToken = _getPushNotificationToken();
    return _storedDeviceId == null || _hasDeviceInfoChanged(pushToken);
  }

  bool _hasDeviceInfoChanged(String currentPushToken) {
    return _lastPlatform != _cachedPlatform ||
        _lastDeviceType != _cachedDeviceType ||
        _lastAppVersion != _cachedAppVersion ||
        _lastDeviceModel != _cachedDeviceModel ||
        _lastPushToken != currentPushToken;
  }

  Future<void> _saveCurrentValuesAsLastKnown(String pushToken) async {
    await Future.wait([
      _storageService.savePlatform(_cachedPlatform),
      _storageService.saveDeviceType(_cachedDeviceType),
      _storageService.saveAppVersion(_cachedAppVersion),
      _storageService.saveDeviceModel(_cachedDeviceModel),
      _storageService.savePushToken(pushToken),
    ]);

    _lastPlatform = _cachedPlatform;
    _lastDeviceType = _cachedDeviceType;
    _lastAppVersion = _cachedAppVersion;
    _lastDeviceModel = _cachedDeviceModel;
    _lastPushToken = pushToken;
  }

  PushNotificationType _getPushNotificationType() {
    if (io.Platform.isAndroid) {
      return PushNotificationType.fcm;
    } else if (io.Platform.isIOS) {
      return PushNotificationType.apns;
    }
    return PushNotificationType.unknown;
  }

  String? getStoredDeviceId() => _cachedDeviceId;

  Future<void> reregister() async {
    await _storageService.clearAll();
    _storedDeviceId = null;
    _cachedDeviceId = null;
    _lastPlatform = null;
    _lastDeviceType = null;
    _lastAppVersion = null;
    _lastDeviceModel = null;
    _lastPushToken = null;
    _storageSnapshotLoaded = false;
    _infoLoaded = false;
    await registerInBackground();
  }
}

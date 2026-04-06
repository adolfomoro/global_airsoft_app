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
    Duration failedSyncRetryInterval = const Duration(seconds: 8),
  }) : _deviceRepository = deviceRepository,
       _storageService = storageService,
       _getPushNotificationToken = getPushNotificationToken,
       _failedSyncRetryInterval = failedSyncRetryInterval;

  final DeviceRepository _deviceRepository;
  final DeviceStorageService _storageService;
  final String Function() _getPushNotificationToken;
  final Duration _failedSyncRetryInterval;

  late String _cachedPlatform;
  late String _cachedDeviceType;
  late String _cachedAppVersion;
  late String? _cachedDeviceModel;
  late String? _cachedDeviceId;
  bool _infoLoaded = false;
  Future<bool>? _inFlightSync;
  DateTime? _nextRetryAt;

  void _debugLog(String message) {
    assert(() {
      debugPrint(message);
      return true;
    }());
  }

  String initializeSync() {
    _cachedDeviceId = _storageService.getDeviceId();
    return _cachedDeviceId ?? '';
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
    final inFlight = _inFlightSync;
    if (inFlight != null) {
      return inFlight;
    }

    final hasStoredDeviceId = _storageService.getDeviceId() != null;
    final now = DateTime.now();
    final retryAt = _nextRetryAt;
    if (hasStoredDeviceId && retryAt != null && now.isBefore(retryAt)) {
      return false;
    }

    final syncFuture = _ensureRegisteredInternal();
    _inFlightSync = syncFuture;

    try {
      return await syncFuture;
    } finally {
      if (identical(_inFlightSync, syncFuture)) {
        _inFlightSync = null;
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
      _nextRetryAt = null;
      return true;
    } catch (e) {
      _nextRetryAt = DateTime.now().add(_failedSyncRetryInterval);
      _debugLog('Device sync failed, next retry at $_nextRetryAt: $e');
      return false;
    }
  }

  /// Register device on first run or update if information changed
  Future<void> _registerOrUpdateDevice() async {
    final storedDeviceId = _storageService.getDeviceId();
    if (storedDeviceId == null || _hasDeviceInfoChanged()) {
      // Register or update device
      final input = RegisterDeviceInputDto(
        deviceId: storedDeviceId,
        platform: _cachedPlatform,
        deviceType: _cachedDeviceType,
        appVersion: _cachedAppVersion,
        deviceModel: _cachedDeviceModel,
        pushNotificationToken: _getPushNotificationToken(),
        pushNotificationType: _getPushNotificationType(),
      );

      final output = await _deviceRepository.registerDevice(input);

      // Update in-memory cache
      _cachedDeviceId = output.deviceId;

      // Save to persistent storage
      await _storageService.saveDeviceId(output.deviceId);

      // Save current values as last known values for change detection
      await _saveCurrentValuesAsLastKnown();

      _debugLog('Device registered: ${output.deviceId}');
    }
  }

  bool _needsRegisterOrUpdate() {
    final storedDeviceId = _storageService.getDeviceId();
    return storedDeviceId == null || _hasDeviceInfoChanged();
  }

  bool _hasDeviceInfoChanged() {
    return _storageService.getLastPlatform() != _cachedPlatform ||
        _storageService.getLastDeviceType() != _cachedDeviceType ||
        _storageService.getLastAppVersion() != _cachedAppVersion ||
        _storageService.getLastDeviceModel() != _cachedDeviceModel ||
        _storageService.getLastPushToken() != _getPushNotificationToken();
  }

  Future<void> _saveCurrentValuesAsLastKnown() async {
    await Future.wait([
      _storageService.savePlatform(_cachedPlatform),
      _storageService.saveDeviceType(_cachedDeviceType),
      _storageService.saveAppVersion(_cachedAppVersion),
      _storageService.saveDeviceModel(_cachedDeviceModel),
      _storageService.savePushToken(_getPushNotificationToken()),
    ]);
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
    _cachedDeviceId = null;
    _infoLoaded = false;
    await registerInBackground();
  }
}

import 'dart:async';
import 'dart:io' as io;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:global_airsoft_app/src/core/logging/app_logger.dart';
import 'package:global_airsoft_app/src/features/device/application/services/device_storage_service.dart';
import 'package:global_airsoft_app/src/features/device/data/repositories/device_repository/device_repository.dart';
import 'package:global_airsoft_app/src/features/device/data/repositories/device_repository/dto/register_device_input_dto.dart';
import 'package:global_airsoft_app/src/features/device/domain/models/push_notification_type.dart';
import 'package:package_info_plus/package_info_plus.dart';

final class DeviceRegistrationService {
  static const String _unknownPlatform = 'Unknown';
  static const String _unknownDeviceType = 'Unknown';
  static const String _initialAppVersion = '0.0.0';
  static const String _emptyPushToken = '';
  static const int _maxSyncAttempts = 3;

  DeviceRegistrationService({
    required DeviceRepository deviceRepository,
    required DeviceStorageService storageService,
    required String Function() getPushNotificationToken,
    required AppLogger logger,
  }) : _deviceRepository = deviceRepository,
       _storageService = storageService,
       _getPushNotificationToken = getPushNotificationToken,
       _logger = logger;

  final DeviceRepository _deviceRepository;
  final DeviceStorageService _storageService;
  final String Function() _getPushNotificationToken;
  final AppLogger _logger;

  String _cachedPlatform = _unknownPlatform;
  String _cachedDeviceType = _unknownDeviceType;
  String _cachedAppVersion = _initialAppVersion;
  String? _cachedDeviceModel;
  String? _storedDeviceId;
  String? _lastPlatform;
  String? _lastDeviceType;
  String? _lastAppVersion;
  String? _lastDeviceModel;
  String? _lastPushToken;
  bool _infoLoaded = false;
  Future<bool>? _inFlightSync;
  Future<void>? _initializeFuture;
  late final PushNotificationType _pushNotificationType =
      _resolvePushNotificationType();

  Future<void> initialize() async {
    final Future<void>? existing = _initializeFuture;
    if (existing != null) {
      await existing;
      return;
    }

    final Future<void> next = _initializeInternal();
    _initializeFuture = next;

    try {
      await next;
    } finally {
      if (identical(_initializeFuture, next)) {
        _initializeFuture = null;
      }
    }
  }

  Future<void> _initializeInternal() async {
    final DeviceStorageSnapshot snapshot = await _storageService.loadSnapshot();

    _storedDeviceId = _normalizeStored(snapshot.deviceId);
    _lastPlatform = _normalizeStored(snapshot.lastPlatform);
    _lastDeviceType = _normalizeStored(snapshot.lastDeviceType);
    _lastAppVersion = _normalizeStored(snapshot.lastAppVersion);
    _lastDeviceModel = _normalizeStored(snapshot.lastDeviceModel);
    _lastPushToken =
        _normalizeStored(snapshot.lastPushToken) ?? _emptyPushToken;
  }

  String? _normalizeStored(String? value) {
    return (value == null || value.isEmpty) ? null : value;
  }

  Future<void> _loadDeviceInfo() async {
    if (_infoLoaded) {
      return;
    }

    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    _cachedAppVersion = packageInfo.version;

    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (io.Platform.isAndroid) {
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      _cachedPlatform = 'Android';
      _cachedDeviceType = androidInfo.device;
      _cachedDeviceModel = androidInfo.model;
    } else if (io.Platform.isIOS) {
      final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      _cachedPlatform = 'iOS';
      _cachedDeviceType = iosInfo.utsname.machine;
      _cachedDeviceModel = iosInfo.model;
    } else {
      _cachedPlatform = _unknownPlatform;
      _cachedDeviceType = _unknownDeviceType;
      _cachedDeviceModel = null;
    }

    _infoLoaded = true;
  }

  Future<void> registerInBackground() async {
    try {
      await ensureRegisteredBeforeRequest();
    } catch (error, stackTrace) {
      _logger.error(
        'Device registration in background failed.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<bool> ensureRegisteredBeforeRequest() async {
    await initialize();

    final String pushToken = _getPushNotificationToken().trim();
    if (pushToken.isEmpty) {
      return true;
    }

    for (int attempt = 0; attempt < _maxSyncAttempts; attempt++) {
      final Future<bool>? inFlight = _inFlightSync;
      if (inFlight != null) {
        final bool inFlightResult = await inFlight;
        if (!inFlightResult) {
          return false;
        }

        if (_isRegistrationUpToDate()) {
          return true;
        }

        continue;
      }

      if (_isRegistrationUpToDate()) {
        return true;
      }

      final Future<bool> syncFuture = _ensureRegisteredInternal();
      _inFlightSync = syncFuture;

      try {
        final bool syncResult = await syncFuture;
        if (!syncResult) {
          return false;
        }

        if (_isRegistrationUpToDate()) {
          return true;
        }
      } finally {
        if (identical(_inFlightSync, syncFuture)) {
          _inFlightSync = null;
        }
      }
    }

    _logger.info('Device sync did not stabilize after max attempts.');
    return false;
  }

  Future<bool> _ensureRegisteredInternal() async {
    await _loadDeviceInfo();

    if (!_needsRegisterOrUpdate()) {
      return true;
    }

    try {
      await _registerOrUpdateDevice();
      return true;
    } catch (error, stackTrace) {
      _logger.error(
        'Device sync failed.',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<void> _registerOrUpdateDevice() async {
    final String? storedDeviceId = _storedDeviceId;
    final String pushToken = _getPushNotificationToken();

    if (pushToken.trim().isEmpty) {
      return;
    }

    if (!_shouldSyncDevice(
      storedDeviceId: storedDeviceId,
      pushToken: pushToken,
    )) {
      return;
    }

    final RegisterDeviceInputDto input = _buildRegisterDeviceInput(
      storedDeviceId: storedDeviceId,
      pushToken: pushToken,
    );

    final output = await _deviceRepository.registerDevice(input);

    await _saveCurrentValuesAsLastKnown(
      pushToken: pushToken,
      deviceId: output.deviceId,
    );

    _storedDeviceId = output.deviceId;
  }

  bool _isRegistrationUpToDate() {
    return !_needsRegisterOrUpdate();
  }

  bool _shouldSyncDevice({
    required String? storedDeviceId,
    required String pushToken,
  }) {
    return storedDeviceId == null || _hasDeviceInfoChanged(pushToken);
  }

  RegisterDeviceInputDto _buildRegisterDeviceInput({
    required String? storedDeviceId,
    required String pushToken,
  }) {
    return RegisterDeviceInputDto(
      deviceId: storedDeviceId,
      platform: _cachedPlatform,
      deviceType: _cachedDeviceType,
      appVersion: _cachedAppVersion,
      deviceModel: _cachedDeviceModel,
      pushNotificationToken: pushToken,
      pushNotificationType: _pushNotificationType,
    );
  }

  bool _needsRegisterOrUpdate() {
    final String pushToken = _getPushNotificationToken();
    if (pushToken.trim().isEmpty) {
      return false;
    }

    return _storedDeviceId == null || _hasDeviceInfoChanged(pushToken);
  }

  bool _hasDeviceInfoChanged(String currentPushToken) {
    return _lastPlatform != _cachedPlatform ||
        _lastDeviceType != _cachedDeviceType ||
        _lastAppVersion != _cachedAppVersion ||
        _lastDeviceModel != _cachedDeviceModel ||
        _lastPushToken != currentPushToken;
  }

  Future<void> _saveCurrentValuesAsLastKnown({
    required String pushToken,
    required String deviceId,
  }) async {
    await _storageService.saveSnapshot(
      DeviceStorageSnapshot(
        deviceId: deviceId,
        lastPlatform: _cachedPlatform,
        lastDeviceType: _cachedDeviceType,
        lastAppVersion: _cachedAppVersion,
        lastDeviceModel: _cachedDeviceModel,
        lastPushToken: pushToken,
      ),
    );

    _lastPlatform = _cachedPlatform;
    _lastDeviceType = _cachedDeviceType;
    _lastAppVersion = _cachedAppVersion;
    _lastDeviceModel = _cachedDeviceModel;
    _lastPushToken = pushToken;
  }

  PushNotificationType _resolvePushNotificationType() {
    if (io.Platform.isAndroid) {
      return PushNotificationType.fcm;
    }
    if (io.Platform.isIOS) {
      return PushNotificationType.apns;
    }
    return PushNotificationType.unknown;
  }

  String? getStoredDeviceId() => _storedDeviceId;
}

import 'preferences_service.dart';

class DeviceStorageService {
  DeviceStorageService({required PreferencesService preferencesService})
    : _prefs = preferencesService;

  final PreferencesService _prefs;

  static const String _deviceIdKey = 'device_id';
  static const String _lastPlatformKey = 'device_last_platform';
  static const String _lastDeviceTypeKey = 'device_last_device_type';
  static const String _lastAppVersionKey = 'device_last_app_version';
  static const String _lastDeviceModelKey = 'device_last_device_model';
  static const String _lastPushTokenKey = 'device_last_push_token';

  String? getDeviceId() => _prefs.getString(_deviceIdKey);

  Future<void> saveDeviceId(String deviceId) =>
      _prefs.setString(_deviceIdKey, deviceId);

  String? getLastPlatform() => _prefs.getString(_lastPlatformKey);

  Future<void> savePlatform(String platform) =>
      _prefs.setString(_lastPlatformKey, platform);

  String? getLastDeviceType() => _prefs.getString(_lastDeviceTypeKey);

  Future<void> saveDeviceType(String deviceType) =>
      _prefs.setString(_lastDeviceTypeKey, deviceType);

  String? getLastAppVersion() => _prefs.getString(_lastAppVersionKey);

  Future<void> saveAppVersion(String appVersion) =>
      _prefs.setString(_lastAppVersionKey, appVersion);

  String? getLastDeviceModel() => _prefs.getString(_lastDeviceModelKey);

  Future<void> saveDeviceModel(String? deviceModel) async {
    if (deviceModel != null) {
      await _prefs.setString(_lastDeviceModelKey, deviceModel);
    }
  }

  String? getLastPushToken() => _prefs.getString(_lastPushTokenKey);

  Future<void> savePushToken(String pushToken) =>
      _prefs.setString(_lastPushTokenKey, pushToken);

  Future<void> clearAll() => _prefs.removeMultiple([
    _deviceIdKey,
    _lastPlatformKey,
    _lastDeviceTypeKey,
    _lastAppVersionKey,
    _lastDeviceModelKey,
    _lastPushTokenKey,
  ]);
}

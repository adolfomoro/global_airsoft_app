import 'package:global_airsoft_app/src/core/storage/key_value_store.dart';

final class NotificationPermissionService {
  NotificationPermissionService({required KeyValueStore store})
    : _store = store;

  final KeyValueStore _store;

  static const String _keyAppOpenCount = 'notification_app_open_count';
  static const String _keyLastPromptOpenCount =
      'notification_last_prompt_open_count';
  static const String _keyPermissionGranted = 'notification_permission_granted';
  static const String _keySystemPermissionRequested =
      'notification_system_permission_requested';
  static const String _keyLoggedInOpenSettingsCooldownUntilOpenCount =
      'notification_logged_in_open_settings_cooldown_until_open_count';

  Future<void> markAppOpened() async {
    final int currentCount = getAppOpenCount();
    await _store.setString(_keyAppOpenCount, (currentCount + 1).toString());
  }

  int getAppOpenCount() {
    return _readInt(_keyAppOpenCount);
  }

  Future<void> markPromptShown() async {
    await _store.setString(
      _keyLastPromptOpenCount,
      getAppOpenCount().toString(),
    );
  }

  int getLastPromptOpenCount() {
    return _readInt(_keyLastPromptOpenCount);
  }

  Future<void> markPermissionGranted() async {
    await _store.setString(_keyPermissionGranted, 'true');
    await _store.setString(_keyLoggedInOpenSettingsCooldownUntilOpenCount, '0');
  }

  Future<void> markSystemPermissionRequested() async {
    await _store.setString(_keySystemPermissionRequested, 'true');
  }

  bool hasPermissionBeenGranted() {
    return _readBool(_keyPermissionGranted);
  }

  bool hasSystemPermissionBeenRequested() {
    return _readBool(_keySystemPermissionRequested);
  }

  bool shouldRequestPermission({required bool isLoggedIn}) {
    if (isLoggedIn) {
      return !isLoggedInOpenSettingsCooldownActive();
    }

    final int appOpenCount = getAppOpenCount();
    if (appOpenCount < 2) {
      return false;
    }

    final int lastPromptOpenCount = getLastPromptOpenCount();
    if (lastPromptOpenCount == 0) {
      return true;
    }

    return (appOpenCount - lastPromptOpenCount) >= 3;
  }

  Future<void> deferOpenSettingsPromptForLoggedIn({int reopenCount = 2}) async {
    final int currentOpenCount = getAppOpenCount();
    final int cooldownUntil = currentOpenCount + reopenCount + 1;
    await _store.setString(
      _keyLoggedInOpenSettingsCooldownUntilOpenCount,
      cooldownUntil.toString(),
    );
  }

  bool isLoggedInOpenSettingsCooldownActive() {
    final int cooldownUntil = _readInt(
      _keyLoggedInOpenSettingsCooldownUntilOpenCount,
    );
    if (cooldownUntil <= 0) {
      return false;
    }

    return getAppOpenCount() < cooldownUntil;
  }

  int _readInt(String key) {
    final String? rawValue = _store.getString(key);
    if (rawValue == null) {
      return 0;
    }

    return int.tryParse(rawValue.trim()) ?? 0;
  }

  bool _readBool(String key) {
    final String? rawValue = _store.getString(key);
    if (rawValue == null) {
      return false;
    }

    return rawValue.trim().toLowerCase() == 'true';
  }
}

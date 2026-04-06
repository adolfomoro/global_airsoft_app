import 'package:shared_preferences/shared_preferences.dart';

class NotificationPermissionService {
  NotificationPermissionService(this._prefs);

  final SharedPreferences _prefs;

  static const String _keyAppOpenCount = 'notification_app_open_count';
  static const String _keyLastPromptOpenCount =
      'notification_last_prompt_open_count';
  static const String _keyPermissionGranted = 'notification_permission_granted';

  Future<void> markAppOpened() async {
    final currentCount = _prefs.getInt(_keyAppOpenCount) ?? 0;
    await _prefs.setInt(_keyAppOpenCount, currentCount + 1);
  }

  int getAppOpenCount() => _prefs.getInt(_keyAppOpenCount) ?? 0;

  Future<void> markPromptShown() async {
    await _prefs.setInt(_keyLastPromptOpenCount, getAppOpenCount());
  }

  int getLastPromptOpenCount() => _prefs.getInt(_keyLastPromptOpenCount) ?? 0;

  Future<void> markPermissionGranted() async {
    await _prefs.setBool(_keyPermissionGranted, true);
  }

  bool hasPermissionBeenGranted() => _prefs.getBool(_keyPermissionGranted) ?? false;

  bool shouldRequestPermission({required bool isLoggedIn}) {
    if (isLoggedIn) {
      return true;
    }

    final appOpenCount = getAppOpenCount();
    if (appOpenCount < 2) {
      return false;
    }

    final lastPromptOpenCount = getLastPromptOpenCount();
    if (lastPromptOpenCount == 0) {
      return true;
    }

    return (appOpenCount - lastPromptOpenCount) >= 3;
  }
}

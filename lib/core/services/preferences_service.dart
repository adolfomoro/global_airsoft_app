import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  PreferencesService({required SharedPreferences prefs}) : _prefs = prefs;

  final SharedPreferences _prefs;

  String? getString(String key) => _prefs.getString(key);

  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  bool? getBool(String key) {
    return _prefs.containsKey(key) ? _prefs.getBool(key) : null;
  }

  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);

  Future<void> remove(String key) => _prefs.remove(key);

  Future<void> removeMultiple(List<String> keys) async {
    await Future.wait(keys.map((key) => _prefs.remove(key)));
  }

  bool contains(String key) => _prefs.containsKey(key);

  Future<void> clearAll() => _prefs.clear();
}

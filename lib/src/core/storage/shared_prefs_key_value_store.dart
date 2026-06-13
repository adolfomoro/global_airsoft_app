import 'package:global_airsoft_app/src/core/storage/key_value_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class SharedPrefsKeyValueStore implements KeyValueStore {
  SharedPrefsKeyValueStore(this._prefs);

  final SharedPreferences _prefs;

  static Future<SharedPrefsKeyValueStore> create() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return SharedPrefsKeyValueStore(prefs);
  }

  @override
  String? getString(String key) {
    return _prefs.getString(key);
  }

  @override
  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  @override
  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }
}

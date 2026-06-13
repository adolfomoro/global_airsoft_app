abstract interface class KeyValueStore {
  String? getString(String key);

  Future<void> setString(String key, String value);

  Future<void> remove(String key);
}

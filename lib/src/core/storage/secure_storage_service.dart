abstract interface class SecureStorageService {
  Future<String?> getString(String key);

  Future<void> setString(String key, String value);

  Future<void> remove(String key);

  Future<void> clear();
}

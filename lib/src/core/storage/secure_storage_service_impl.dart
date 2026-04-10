import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:global_airsoft_app/src/core/storage/secure_storage_service.dart';

final class SecureStorageServiceImpl implements SecureStorageService {
  SecureStorageServiceImpl(this._storage);

  final FlutterSecureStorage _storage;

  factory SecureStorageServiceImpl.create() {
    const iOSOptions = IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    );

    const androidOptions = AndroidOptions(resetOnError: true);

    final storage = FlutterSecureStorage(
      aOptions: androidOptions,
      iOptions: iOSOptions,
    );

    return SecureStorageServiceImpl(storage);
  }

  @override
  Future<String?> getString(String key) async {
    return await _storage.read(key: key);
  }

  @override
  Future<void> setString(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  @override
  Future<void> remove(String key) async {
    await _storage.delete(key: key);
  }

  @override
  Future<void> clear() async {
    await _storage.deleteAll();
  }
}

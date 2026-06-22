import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:global_airsoft_app/src/core/storage/key_value_store.dart';
import 'package:global_airsoft_app/src/core/storage/secure_storage_service.dart';
import 'package:global_airsoft_app/src/features/auth/application/services/auth_security_bootstrapper.dart';
import 'package:global_airsoft_app/src/features/auth/application/services/auth_security_coordinator.dart';
import 'package:global_airsoft_app/src/features/auth/application/services/auth_storage_service.dart';
import 'package:global_airsoft_app/src/features/auth/domain/models/auth_tokens.dart';

final class _InMemorySecureStorageService implements SecureStorageService {
  final Map<String, String> data = <String, String>{};

  @override
  Future<void> clear() async {
    data.clear();
  }

  @override
  Future<String?> getString(String key) async {
    return data[key];
  }

  @override
  Future<void> remove(String key) async {
    data.remove(key);
  }

  @override
  Future<void> setString(String key, String value) async {
    data[key] = value;
  }
}

final class _InMemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> data = <String, String>{};

  @override
  String? getString(String key) {
    return data[key];
  }

  @override
  Future<void> remove(String key) async {
    data.remove(key);
  }

  @override
  Future<void> setString(String key, String value) async {
    data[key] = value;
  }
}

void main() {
  test('configure wires coordinator clearSession with local cleanup', () async {
    final AuthSecurityCoordinator coordinator = AuthSecurityCoordinator();
    final _InMemorySecureStorageService secureStorage =
        _InMemorySecureStorageService();
    final _InMemoryKeyValueStore keyValueStore = _InMemoryKeyValueStore();
    final AuthStorageService authStorageService = AuthStorageService(
      secureStorage: secureStorage,
    );

    int localCleanupCalls = 0;
    int unauthenticatedCalls = 0;

    await secureStorage.setString(
      'auth_tokens',
      jsonEncode(const AuthTokens(jwtToken: 'jwt', refreshToken: 'refresh').toJson()),
    );
    keyValueStore.data['user_id_for_backup'] = 'user-id';

    final AuthSecurityBootstrapper bootstrapper = AuthSecurityBootstrapper(
      coordinator: coordinator,
      authStorageService: authStorageService,
      refreshTokens: (String refreshToken) async {
        return const AuthTokens(
          jwtToken: 'jwt-next',
          refreshToken: 'refresh-next',
        );
      },
      keyValueStore: keyValueStore,
      clearLocalSessionData: () async {
        localCleanupCalls += 1;
      },
      setUnauthenticated: () {
        unauthenticatedCalls += 1;
      },
    );

    bootstrapper.configure(
      initialTokens: const AuthTokens(jwtToken: 'jwt', refreshToken: 'refresh'),
      translateMessage: (String key) async => key,
      showMessage: (String message, {Object? source}) async {},
    );

    await coordinator.clearSession();

    expect(localCleanupCalls, 1);
    expect(unauthenticatedCalls, 1);
    expect(await secureStorage.getString('auth_tokens'), isNull);
    expect(keyValueStore.getString('user_id_for_backup'), isNull);
  });
}

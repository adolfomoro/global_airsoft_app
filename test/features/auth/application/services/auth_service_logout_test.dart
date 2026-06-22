import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_airsoft_app/src/core/config/app_config.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localization_service.dart';
import 'package:global_airsoft_app/src/core/logging/app_logger.dart';
import 'package:global_airsoft_app/src/core/network/app_dio_service.dart';
import 'package:global_airsoft_app/src/core/storage/secure_storage_service.dart';
import 'package:global_airsoft_app/src/core/storage/shared_prefs_key_value_store.dart';
import 'package:global_airsoft_app/src/features/auth/application/services/auth_security_coordinator.dart';
import 'package:global_airsoft_app/src/features/auth/application/services/auth_service.dart';
import 'package:global_airsoft_app/src/features/auth/application/services/auth_storage_service.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/auth_repository.dart';
import 'package:global_airsoft_app/src/features/auth/domain/models/auth_profile.dart';
import 'package:global_airsoft_app/src/features/auth/domain/models/auth_tokens.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class _InMemorySecureStorageService implements SecureStorageService {
  _InMemorySecureStorageService(this.events);

  final List<String> events;
  final Map<String, String> values = <String, String>{};

  @override
  Future<String?> getString(String key) async {
    return values[key];
  }

  @override
  Future<void> setString(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    values.remove(key);
    events.add('secure-remove:$key');
  }

  @override
  Future<void> clear() async {
    values.clear();
    events.add('secure-clear');
  }
}

final class _FakeHttpClientAdapter implements HttpClientAdapter {
  _FakeHttpClientAdapter({
    required this.events,
    required this.logoutStatusCode,
  });

  final List<String> events;
  final int logoutStatusCode;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    events.add('server:${options.method}:${options.path}');
    await requestStream?.drain<void>();

    return ResponseBody.fromString(
      '{"ok":true}',
      logoutStatusCode,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Future<AuthService> _buildAuthService({
  required int logoutStatusCode,
  required List<String> events,
  required SecureStorageService secureStorageService,
  required SharedPrefsKeyValueStore sharedPrefs,
  Future<void> Function()? clearLocalSessionData,
}) async {
  final AppConfig config = AppConfig(
    environment: AppEnvironment.test,
    enableDebugLogs: false,
    apiBaseUrl: 'https://api.example.com',
    apiVersion: '',
    connectTimeoutMs: 5000,
    receiveTimeoutMs: 5000,
    sendTimeoutMs: 5000,
    datadogEnabled: false,
    datadogClientToken: '',
    datadogRumApplicationId: '',
    datadogServiceName: 'global_airsoft_app',
    datadogSite: 'us1',
    googleSignInServerClientId: '',
  );

  final AppLocalizationService localizationService = AppLocalizationService(
    locale: const Locale('en'),
  );

  final AppDioService dioService = AppDioService.create(
    config: config,
    logger: AppLogger.instance,
    getDeviceLanguage: () => 'en',
    onContentLanguage: (_) async {},
    apiExceptionMessagesResolver: () {
      return buildLocalizedApiExceptionMessages(localizationService);
    },
    deviceSyncRequiredMessageResolver: () {
      return localizationService.tr(AppLocaleKeys.commonGenericApiErrorMessage);
    },
  );
  dioService.client.httpClientAdapter = _FakeHttpClientAdapter(
    events: events,
    logoutStatusCode: logoutStatusCode,
  );

  final AuthRepository authRepository = AuthRepository(
    dioService: dioService,
    localizationService: localizationService,
  );

  final AuthStorageService authStorageService = AuthStorageService(
    secureStorage: secureStorageService,
  );

  final AuthSecurityCoordinator authSecurityCoordinator =
      AuthSecurityCoordinator();

  return AuthService(
    authRepository: authRepository,
    authStorageService: authStorageService,
    authSecurityCoordinator: authSecurityCoordinator,
    sharedPrefs: sharedPrefs,
    clearLocalSessionData:
        clearLocalSessionData ??
        () async {
          events.add('local-cleanup');
        },
    logger: AppLogger.instance,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('logout notifies backend before clearing local session', () async {
    final List<String> events = <String>[];

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final SharedPrefsKeyValueStore sharedPrefs = SharedPrefsKeyValueStore(
      prefs,
    );
    final _InMemorySecureStorageService secureStorageService =
        _InMemorySecureStorageService(events);
    final AuthStorageService authStorageService = AuthStorageService(
      secureStorage: secureStorageService,
    );
    await authStorageService.saveTokens(
      const AuthTokens(jwtToken: 'jwt-token', refreshToken: 'refresh-token'),
    );
    await authStorageService.saveProfile(
      const AuthProfile(userId: 'user-1', username: 'tester'),
    );
    await sharedPrefs.setString('user_id_for_backup', 'user-1');

    final AuthService authService = await _buildAuthService(
      logoutStatusCode: HttpStatus.ok,
      events: events,
      secureStorageService: secureStorageService,
      sharedPrefs: sharedPrefs,
    );

    await authService.logout();

    expect(events.first, 'server:DELETE:/auth/logout');
    expect(events.skip(1).toSet(), <String>{
      'local-cleanup',
      'secure-remove:auth_tokens',
      'secure-remove:auth_profile',
    });
    expect(await authStorageService.getTokens(), isNull);
    expect(await authStorageService.getProfile(), isNull);
    expect(sharedPrefs.getString('user_id_for_backup'), isNull);
  });

  test('logout fails when backend rejects', () async {
    final List<String> events = <String>[];

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final SharedPrefsKeyValueStore sharedPrefs = SharedPrefsKeyValueStore(
      prefs,
    );
    final _InMemorySecureStorageService secureStorageService =
        _InMemorySecureStorageService(events);
    final AuthStorageService authStorageService = AuthStorageService(
      secureStorage: secureStorageService,
    );
    await authStorageService.saveTokens(
      const AuthTokens(jwtToken: 'jwt-token', refreshToken: 'refresh-token'),
    );
    await authStorageService.saveProfile(
      const AuthProfile(userId: 'user-1', username: 'tester'),
    );
    await sharedPrefs.setString('user_id_for_backup', 'user-1');

    final AuthService authService = await _buildAuthService(
      logoutStatusCode: HttpStatus.internalServerError,
      events: events,
      secureStorageService: secureStorageService,
      sharedPrefs: sharedPrefs,
    );

    // When backend fails, logout should throw and local session cleanup is not attempted
    await expectLater(
      authService.logout(),
      throwsA(isA<Exception>()),
    );

    expect(events.first, 'server:DELETE:/auth/logout');
    // No local cleanup should happen when backend fails
    expect(events, hasLength(1));
    // Session data should still be stored
    expect(await authStorageService.getTokens(), isNotNull);
    expect(await authStorageService.getProfile(), isNotNull);
    expect(sharedPrefs.getString('user_id_for_backup'), 'user-1');
  });
}

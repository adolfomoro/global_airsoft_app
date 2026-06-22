import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_airsoft_app/src/core/config/app_config.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localization_service.dart';
import 'package:global_airsoft_app/src/core/logging/app_logger.dart';
import 'package:global_airsoft_app/src/core/network/api_exception.dart';
import 'package:global_airsoft_app/src/core/network/app_dio_service.dart';
import 'package:global_airsoft_app/src/core/network/auth_security_handled_exception.dart';
import 'package:global_airsoft_app/src/core/network/constants/app_network_headers.dart';
import 'package:global_airsoft_app/src/features/auth/application/services/auth_security_coordinator.dart';
import 'package:global_airsoft_app/src/features/auth/domain/models/auth_tokens.dart';

final class _RequestSnapshot {
  const _RequestSnapshot({
    required this.path,
    required this.authorization,
    required this.deviceId,
    required this.userAgent,
  });

  final String path;
  final String? authorization;
  final String? deviceId;
  final String? userAgent;
}

final class _RecordingHttpClientAdapter implements HttpClientAdapter {
  _RecordingHttpClientAdapter({required this.respond});

  final Future<ResponseBody> Function(RequestOptions options) respond;
  final List<_RequestSnapshot> snapshots = <_RequestSnapshot>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await requestStream?.drain<void>();
    snapshots.add(
      _RequestSnapshot(
        path: options.path,
        authorization: options.headers['Authorization'] as String?,
        deviceId: options.headers['X-Device-Id'] as String?,
        userAgent: options.headers[AppNetworkHeaders.userAgentHeader] as String?,
      ),
    );

    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

AppConfig _buildTestConfig() {
  return AppConfig(
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
}

ResponseBody _jsonBody(String json, int statusCode) {
  return ResponseBody.fromString(
    json,
    statusCode,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>[Headers.jsonContentType],
    },
  );
}

ResponseBody _errorBody({
  required String code,
  required int statusCode,
  String? message,
}) {
  final Map<String, Object?> error = <String, Object?>{'code': code};
  if (message != null) {
    error['message'] = message;
  }

  return ResponseBody.fromString(
    jsonEncode(<String, Object?>{'error': error}),
    statusCode,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      'AbpErrorFormat': <String>['true'],
    },
  );
}

Future<AppDioService> _buildService(
  _RecordingHttpClientAdapter adapter, {
  required AuthSecurityCoordinator coordinator,
  Locale locale = const Locale('en'),
  bool enableAuthSecurityInterceptor = true,
}) async {
  final AppLocalizationService localizationService = AppLocalizationService(
    locale: locale,
  );

  final AppDioService service = AppDioService.create(
    config: _buildTestConfig(),
    logger: AppLogger.instance,
    getDeviceId: () => 'device-123',
    ensureDeviceSynced: () async => true,
    getDeviceLanguage: () => 'en',
    onContentLanguage: (_) async {},
    apiExceptionMessagesResolver: () {
      return buildLocalizedApiExceptionMessages(localizationService);
    },
    deviceSyncRequiredMessageResolver: () {
      return localizationService.tr(AppLocaleKeys.commonGenericApiErrorMessage);
    },
    enableAuthSecurityInterceptor: enableAuthSecurityInterceptor,
    authSecurityCoordinator: enableAuthSecurityInterceptor
        ? coordinator
        : null,
  );

  service.client.httpClientAdapter = adapter;
  return service;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AuthSecurityCoordinator coordinator;

  setUp(() {
    coordinator = AuthSecurityCoordinator();
  });

  tearDown(() {
    coordinator.reset();
  });

  test(
    'waits for an in-flight refresh before releasing concurrent requests',
    () async {
      final List<String> messages = <String>[];
      AuthTokens currentTokens = const AuthTokens(
        jwtToken: 'old-access-token',
        refreshToken: 'old-refresh-token',
      );
      int refreshCalls = 0;
      int clearCalls = 0;
      final Completer<AuthTokens> refreshCompleter = Completer<AuthTokens>();
      final Completer<void> refreshStarted = Completer<void>();
      int protectedRequestCount = 0;

      coordinator.configure(
        getTokens: () async => currentTokens,
        saveTokens: (AuthTokens tokens) async {
          currentTokens = tokens;
        },
        clearSession: () async {
          clearCalls += 1;
          currentTokens = const AuthTokens(jwtToken: '', refreshToken: '');
        },
        refreshTokens: (String refreshToken) {
          refreshCalls += 1;
          if (!refreshStarted.isCompleted) {
            refreshStarted.complete();
          }

          return refreshCompleter.future;
        },
        translateMessage: (String key) async => key,
        showMessage: (String message, {Object? source}) async {
          messages.add(message);
        },
      );

      final _RecordingHttpClientAdapter adapter = _RecordingHttpClientAdapter(
        respond: (RequestOptions options) async {
          if (options.path != '/protected') {
            return _jsonBody('{"ok":true}', HttpStatus.ok);
          }

          protectedRequestCount += 1;

          final String? authorization =
              options.headers['Authorization'] as String?;
          if (authorization == 'Bearer old-access-token') {
            return _errorBody(
              code: 'GlobalAirsoft:Auth:AccessTokenExpired',
              statusCode: HttpStatus.unauthorized,
            );
          }

          if (authorization == 'Bearer new-access-token') {
            return _jsonBody('{"ok":true}', HttpStatus.ok);
          }

          return _errorBody(
            code: 'GlobalAirsoft:Auth:AccessTokenExpired',
            statusCode: HttpStatus.unauthorized,
          );
        },
      );

      final AppDioService service = await _buildService(adapter, coordinator: coordinator);

      final Future<Response<dynamic>> firstRequest = service.get<dynamic>(
        '/protected',
      );

      await Future<void>.delayed(Duration.zero);
      await refreshStarted.future;
      final Future<Response<dynamic>> secondRequest = service.get<dynamic>(
        '/protected',
      );
      await Future<void>.delayed(Duration.zero);

      expect(protectedRequestCount, 1);

      refreshCompleter.complete(
        const AuthTokens(
          jwtToken: 'new-access-token',
          refreshToken: 'new-refresh-token',
        ),
      );

      final List<Response<dynamic>> responses =
          await Future.wait<Response<dynamic>>(<Future<Response<dynamic>>>[
            firstRequest,
            secondRequest,
          ]);

      expect(refreshCalls, 1);
      expect(clearCalls, 0);
      expect(messages, isEmpty);
      expect(currentTokens.jwtToken, 'new-access-token');
      expect(currentTokens.refreshToken, 'new-refresh-token');
      expect(protectedRequestCount, 3);
      expect(responses, hasLength(2));
      expect(
        adapter.snapshots
            .where((snapshot) {
              return snapshot.path == '/protected';
            })
            .every((snapshot) {
              return snapshot.deviceId == 'device-123';
            }),
        isTrue,
      );
      expect(
        adapter.snapshots
            .where((snapshot) {
              return snapshot.path == '/protected';
            })
            .every((snapshot) {
              return snapshot.userAgent == AppNetworkHeaders.userAgentValue;
            }),
        isTrue,
      );
      expect(
        adapter.snapshots
            .where((snapshot) {
              return snapshot.path == '/protected';
            })
            .any((snapshot) {
              return snapshot.authorization == 'Bearer new-access-token';
            }),
        isTrue,
      );
    },
  );

  test('logs out immediately on invalid access token', () async {
    final List<String> messages = <String>[];
    AuthTokens currentTokens = const AuthTokens(
      jwtToken: 'old-access-token',
      refreshToken: 'old-refresh-token',
    );
    int refreshCalls = 0;
    int clearCalls = 0;

    coordinator.configure(
      getTokens: () async => currentTokens,
      saveTokens: (AuthTokens tokens) async {
        currentTokens = tokens;
      },
      clearSession: () async {
        clearCalls += 1;
        currentTokens = const AuthTokens(jwtToken: '', refreshToken: '');
      },
      refreshTokens: (String refreshToken) {
        refreshCalls += 1;
        return Future<AuthTokens>.value(
          const AuthTokens(jwtToken: 'unexpected', refreshToken: 'unexpected'),
        );
      },
      translateMessage: (String key) async {
        return switch (key) {
          AppLocaleKeys.authSessionEndedForSecurityMessage =>
            'Your session ended for security reasons. Please sign in again.',
          AppLocaleKeys.authSecurityChangeDetectedMessage =>
            'We detected a security change. Please sign in again.',
          _ => key,
        };
      },
        showMessage: (String message, {Object? source}) async {
          messages.add(message);
        },
    );

    final _RecordingHttpClientAdapter adapter = _RecordingHttpClientAdapter(
      respond: (RequestOptions options) async {
        return _errorBody(
          code: 'GlobalAirsoft:Auth:AccessTokenInvalid',
          message: 'Backend security change message.',
          statusCode: HttpStatus.unauthorized,
        );
      },
    );

    final AppDioService service = await _buildService(adapter, coordinator: coordinator);

    await expectLater(
      service.get<dynamic>('/protected'),
      throwsA(
        isA<AuthSecurityHandledException>()
            .having(
              (AuthSecurityHandledException error) => error.code,
              'code',
              'GlobalAirsoft:Auth:AccessTokenInvalid',
            )
            .having(
              (AuthSecurityHandledException error) => error.reason,
              'reason',
              'GlobalAirsoft:Auth:AccessTokenInvalid',
            )
            .having(
              (AuthSecurityHandledException error) => error.message,
              'message',
              'We detected a security change. Please sign in again.',
            ),
      ),
    );

    expect(refreshCalls, 0);
    expect(clearCalls, 1);
    expect(currentTokens.jwtToken, isEmpty);
    expect(currentTokens.refreshToken, isEmpty);
    expect(messages, <String>[
      'We detected a security change. Please sign in again.',
    ]);
  });

  test('goes to login without refresh on auth required', () async {
    final List<String> messages = <String>[];
    AuthTokens currentTokens = const AuthTokens(
      jwtToken: 'old-access-token',
      refreshToken: 'old-refresh-token',
    );
    int refreshCalls = 0;
    int clearCalls = 0;

    coordinator.configure(
      getTokens: () async => currentTokens,
      saveTokens: (AuthTokens tokens) async {
        currentTokens = tokens;
      },
      clearSession: () async {
        clearCalls += 1;
        currentTokens = const AuthTokens(jwtToken: '', refreshToken: '');
      },
      refreshTokens: (String refreshToken) {
        refreshCalls += 1;
        return Future<AuthTokens>.value(
          const AuthTokens(jwtToken: 'unexpected', refreshToken: 'unexpected'),
        );
      },
      translateMessage: (String key) async {
        return switch (key) {
          AppLocaleKeys.authSecurityChangeDetectedMessage =>
            'Please sign in again to continue.',
          _ => key,
        };
      },
        showMessage: (String message, {Object? source}) async {
          messages.add(message);
        },
    );

    final _RecordingHttpClientAdapter adapter = _RecordingHttpClientAdapter(
      respond: (RequestOptions options) async {
        return _errorBody(
          code: 'GlobalAirsoft:Auth:AuthRequired',
          statusCode: HttpStatus.unauthorized,
        );
      },
    );

    final AppDioService service = await _buildService(adapter, coordinator: coordinator);

    await expectLater(
      service.get<dynamic>('/protected'),
      throwsA(
        isA<AuthSecurityHandledException>()
            .having(
              (AuthSecurityHandledException error) => error.code,
              'code',
              'GlobalAirsoft:Auth:AuthRequired',
            )
            .having(
              (AuthSecurityHandledException error) => error.message,
              'message',
              'Please sign in again to continue.',
            ),
      ),
    );

    expect(refreshCalls, 0);
    expect(clearCalls, 1);
    expect(currentTokens.jwtToken, isEmpty);
    expect(currentTokens.refreshToken, isEmpty);
    expect(messages, <String>['Please sign in again to continue.']);
  });

  test('logs out immediately on session ended', () async {
    final List<String> messages = <String>[];
    AuthTokens currentTokens = const AuthTokens(
      jwtToken: 'old-access-token',
      refreshToken: 'old-refresh-token',
    );
    int refreshCalls = 0;
    int clearCalls = 0;

    coordinator.configure(
      getTokens: () async => currentTokens,
      saveTokens: (AuthTokens tokens) async {
        currentTokens = tokens;
      },
      clearSession: () async {
        clearCalls += 1;
        currentTokens = const AuthTokens(jwtToken: '', refreshToken: '');
      },
      refreshTokens: (String refreshToken) {
        refreshCalls += 1;
        return Future<AuthTokens>.value(
          const AuthTokens(jwtToken: 'unexpected', refreshToken: 'unexpected'),
        );
      },
      translateMessage: (String key) async {
        return switch (key) {
          AppLocaleKeys.authSessionEndedForSecurityMessage =>
            'Your session ended. Please sign in again.',
          _ => key,
        };
      },
        showMessage: (String message, {Object? source}) async {
          messages.add(message);
        },
    );

    final _RecordingHttpClientAdapter adapter = _RecordingHttpClientAdapter(
      respond: (RequestOptions options) async {
        return _errorBody(
          code: 'GlobalAirsoft:Auth:SessionEnded',
          statusCode: HttpStatus.unauthorized,
        );
      },
    );

    final AppDioService service = await _buildService(adapter, coordinator: coordinator);

    await expectLater(
      service.get<dynamic>('/protected'),
      throwsA(
        isA<AuthSecurityHandledException>()
            .having(
              (AuthSecurityHandledException error) => error.code,
              'code',
              'GlobalAirsoft:Auth:SessionEnded',
            )
            .having(
              (AuthSecurityHandledException error) => error.message,
              'message',
              'Your session ended. Please sign in again.',
            ),
      ),
    );

    expect(refreshCalls, 0);
    expect(clearCalls, 1);
    expect(currentTokens.jwtToken, isEmpty);
    expect(currentTokens.refreshToken, isEmpty);
    expect(messages, <String>['Your session ended. Please sign in again.']);
  });

  test('logs out when token refresh fails', () async {
    final List<String> messages = <String>[];
    AuthTokens currentTokens = const AuthTokens(
      jwtToken: 'old-access-token',
      refreshToken: 'old-refresh-token',
    );
    int refreshCalls = 0;
    int clearCalls = 0;

    coordinator.configure(
      getTokens: () async => currentTokens,
      saveTokens: (AuthTokens tokens) async {
        currentTokens = tokens;
      },
      clearSession: () async {
        clearCalls += 1;
        currentTokens = const AuthTokens(jwtToken: '', refreshToken: '');
      },
      refreshTokens: (String refreshToken) {
        refreshCalls += 1;
        return Future<AuthTokens>.error(StateError('refresh failed'));
      },
      translateMessage: (String key) async {
        return switch (key) {
          AppLocaleKeys.authSessionEndedForSecurityMessage =>
            'Your session ended for security reasons. Please sign in again.',
          _ => key,
        };
      },
        showMessage: (String message, {Object? source}) async {
          messages.add(message);
        },
    );

    final _RecordingHttpClientAdapter adapter = _RecordingHttpClientAdapter(
      respond: (RequestOptions options) async {
        return _errorBody(
          code: 'GlobalAirsoft:Auth:AccessTokenExpired',
          statusCode: HttpStatus.unauthorized,
        );
      },
    );

    final AppDioService service = await _buildService(adapter, coordinator: coordinator);

    Object? caughtError;
    try {
      await service.get<dynamic>('/protected');
    } catch (error) {
      caughtError = error;
    }

    expect(caughtError, isA<AuthSecurityHandledException>());

    expect(refreshCalls, 1);
    expect(clearCalls, 1);
    expect(currentTokens.jwtToken, isEmpty);
    expect(currentTokens.refreshToken, isEmpty);
    expect(messages, <String>[
      'Your session ended for security reasons. Please sign in again.',
    ]);
  });

  test(
    'does not refresh or logout when access expired code is not unauthorized',
    () async {
      final List<String> messages = <String>[];
      AuthTokens currentTokens = const AuthTokens(
        jwtToken: 'old-access-token',
        refreshToken: 'old-refresh-token',
      );
      int refreshCalls = 0;
      int clearCalls = 0;

      coordinator.configure(
        getTokens: () async => currentTokens,
        saveTokens: (AuthTokens tokens) async {
          currentTokens = tokens;
        },
        clearSession: () async {
          clearCalls += 1;
          currentTokens = const AuthTokens(jwtToken: '', refreshToken: '');
        },
        refreshTokens: (String refreshToken) {
          refreshCalls += 1;
          return Future<AuthTokens>.value(
            const AuthTokens(
              jwtToken: 'unexpected',
              refreshToken: 'unexpected',
            ),
          );
        },
        translateMessage: (String key) async {
          return switch (key) {
            AppLocaleKeys.authServerUnavailableMessage =>
              'Unable to complete this now. Please try again.',
            _ => key,
          };
        },
        showMessage: (String message, {Object? source}) async {
          messages.add(message);
        },
      );

      final _RecordingHttpClientAdapter adapter = _RecordingHttpClientAdapter(
        respond: (RequestOptions options) async {
          return _errorBody(
            code: 'GlobalAirsoft:Auth:AccessTokenExpired',
            statusCode: HttpStatus.internalServerError,
          );
        },
      );

      final AppDioService service = await _buildService(adapter, coordinator: coordinator);

      await expectLater(
        service.get<dynamic>('/protected'),
        throwsA(
          isA<AuthSecurityHandledException>()
              .having(
                (AuthSecurityHandledException error) => error.code,
                'code',
                'GlobalAirsoft:Auth:AccessTokenExpired',
              )
              .having(
                (AuthSecurityHandledException error) => error.statusCode,
                'statusCode',
                HttpStatus.internalServerError,
              )
              .having(
                (AuthSecurityHandledException error) => error.message,
                'message',
                'Unable to complete this now. Please try again.',
              ),
        ),
      );

      expect(refreshCalls, 0);
      expect(clearCalls, 0);
      expect(currentTokens.jwtToken, 'old-access-token');
      expect(currentTokens.refreshToken, 'old-refresh-token');
      expect(messages, <String>[
        'Unable to complete this now. Please try again.',
      ]);
    },
  );

  test('shows permission denied without logging out', () async {
    final List<String> messages = <String>[];
    AuthTokens currentTokens = const AuthTokens(
      jwtToken: 'old-access-token',
      refreshToken: 'old-refresh-token',
    );
    int refreshCalls = 0;
    int clearCalls = 0;

    coordinator.configure(
      getTokens: () async => currentTokens,
      saveTokens: (AuthTokens tokens) async {
        currentTokens = tokens;
      },
      clearSession: () async {
        clearCalls += 1;
        currentTokens = const AuthTokens(jwtToken: '', refreshToken: '');
      },
      refreshTokens: (String refreshToken) {
        refreshCalls += 1;
        return Future<AuthTokens>.value(
          const AuthTokens(jwtToken: 'unexpected', refreshToken: 'unexpected'),
        );
      },
      translateMessage: (String key) async {
        return switch (key) {
          AppLocaleKeys.authPermissionDeniedMessage =>
            'You do not have permission to access this resource.',
          _ => key,
        };
      },
        showMessage: (String message, {Object? source}) async {
          messages.add(message);
        },
    );

    final _RecordingHttpClientAdapter adapter = _RecordingHttpClientAdapter(
      respond: (RequestOptions options) async {
        return _errorBody(
          code: 'GlobalAirsoft:Auth:AccessForbidden',
          message: null,
          statusCode: HttpStatus.forbidden,
        );
      },
    );

    final AppDioService service = await _buildService(adapter, coordinator: coordinator);

    await expectLater(
      service.get<dynamic>('/protected'),
      throwsA(
        isA<AuthSecurityHandledException>()
            .having(
              (AuthSecurityHandledException error) => error.code,
              'code',
              'GlobalAirsoft:Auth:AccessForbidden',
            )
            .having(
              (AuthSecurityHandledException error) => error.message,
              'message',
              'You do not have permission to access this resource.',
            ),
      ),
    );

    expect(refreshCalls, 0);
    expect(clearCalls, 0);
    expect(currentTokens.jwtToken, 'old-access-token');
    expect(currentTokens.refreshToken, 'old-refresh-token');
    expect(messages, <String>[
      'You do not have permission to access this resource.',
    ]);
  });

  test('does not treat generic forbidden responses as access forbidden', () async {
    final List<String> messages = <String>[];
    AuthTokens currentTokens = const AuthTokens(
      jwtToken: 'old-access-token',
      refreshToken: 'old-refresh-token',
    );
    int refreshCalls = 0;
    int clearCalls = 0;

    coordinator.configure(
      getTokens: () async => currentTokens,
      saveTokens: (AuthTokens tokens) async {
        currentTokens = tokens;
      },
      clearSession: () async {
        clearCalls += 1;
        currentTokens = const AuthTokens(jwtToken: '', refreshToken: '');
      },
      refreshTokens: (String refreshToken) {
        refreshCalls += 1;
        return Future<AuthTokens>.value(
          const AuthTokens(
            jwtToken: 'unexpected',
            refreshToken: 'unexpected',
          ),
        );
      },
      translateMessage: (String key) async => key,
      showMessage: (String message, {Object? source}) async {
        messages.add(message);
      },
    );

    final _RecordingHttpClientAdapter adapter = _RecordingHttpClientAdapter(
      respond: (RequestOptions options) async {
        return _errorBody(
          code: 'GlobalAirsoft:GenericForbidden',
          message: 'Forbidden by backend.',
          statusCode: HttpStatus.forbidden,
        );
      },
    );

    final AppDioService service = await _buildService(adapter, coordinator: coordinator);

    await expectLater(
      service.get<dynamic>('/protected'),
      throwsA(
        isA<ForbiddenApiException>()
            .having(
              (ForbiddenApiException error) => error.code,
              'code',
              'GlobalAirsoft:GenericForbidden',
            )
            .having(
              (ForbiddenApiException error) => error.message,
              'message',
              'Forbidden by backend.',
            ),
      ),
    );

    expect(refreshCalls, 0);
    expect(clearCalls, 0);
    expect(currentTokens.jwtToken, 'old-access-token');
    expect(currentTokens.refreshToken, 'old-refresh-token');
    expect(messages, isEmpty);
  });

  test(
    'uses localized generic fallback when backend message is absent',
    () async {
      final _RecordingHttpClientAdapter adapter = _RecordingHttpClientAdapter(
        respond: (RequestOptions options) async {
          return _jsonBody(
            '{"error":{"code":"GlobalAirsoft:GenericError"}}',
            HttpStatus.internalServerError,
          );
        },
      );

      final AppDioService service = await _buildService(
        adapter,
        coordinator: coordinator,
        locale: const Locale('pt', 'BR'),
        enableAuthSecurityInterceptor: false,
      );

      await expectLater(
        service.get<dynamic>('/generic-error'),
        throwsA(
          isA<ApiException>()
              .having(
                (ApiException error) => error.statusCode,
                'statusCode',
                HttpStatus.internalServerError,
              )
              .having(
                (ApiException error) => error.message,
                'message',
                'Ocorreu um erro. Tente novamente mais tarde.',
              )
              .having(
                (ApiException error) => error.isFallbackMessage,
                'isFallbackMessage',
                isTrue,
              ),
        ),
      );
    },
  );

  test('preserves correlation id when auth security wraps server failures', () async {
    final List<Object?> sources = <Object?>[];
    AuthTokens currentTokens = const AuthTokens(
      jwtToken: 'old-access-token',
      refreshToken: 'old-refresh-token',
    );

    coordinator.configure(
      getTokens: () async => currentTokens,
      saveTokens: (AuthTokens tokens) async {
        currentTokens = tokens;
      },
      clearSession: () async {},
      refreshTokens: (String refreshToken) {
        return Future<AuthTokens>.value(
          const AuthTokens(jwtToken: 'unexpected', refreshToken: 'unexpected'),
        );
      },
      translateMessage: (String key) async => 'Server unavailable.',
      showMessage: (String message, {Object? source}) async {
        sources.add(source);
      },
    );

    final _RecordingHttpClientAdapter adapter = _RecordingHttpClientAdapter(
      respond: (RequestOptions options) async {
        return ResponseBody.fromString(
          jsonEncode(
            <String, Object?>{
              'error': <String, Object?>{'code': 'GlobalAirsoft:ServerError'},
            },
          ),
          HttpStatus.internalServerError,
          headers: <String, List<String>>{
            Headers.contentTypeHeader: <String>[Headers.jsonContentType],
            'AbpErrorFormat': <String>['true'],
            'X-Correlation-Id': <String>['corr-auth-500'],
          },
        );
      },
    );

    final AppDioService service = await _buildService(adapter, coordinator: coordinator);

    await expectLater(
      service.get<dynamic>('/protected'),
      throwsA(
        isA<AuthSecurityHandledException>().having(
          (AuthSecurityHandledException error) => error.correlationId,
          'correlationId',
          'corr-auth-500',
        ),
      ),
    );

    expect(
      sources.single,
      isA<AuthSecurityHandledException>().having(
        (AuthSecurityHandledException error) => error.correlationId,
        'correlationId',
        'corr-auth-500',
      ),
    );
  });
}

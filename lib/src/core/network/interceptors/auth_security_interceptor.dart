import 'dart:async';

import 'package:dio/dio.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/network/api_exception.dart';
import 'package:global_airsoft_app/src/core/network/api_exception_formatter.dart';
import 'package:global_airsoft_app/src/core/network/auth_security_handled_exception.dart';
import 'package:global_airsoft_app/src/features/auth/application/services/auth_security_coordinator.dart';
import 'package:global_airsoft_app/src/features/auth/data/constants/auth_api_paths.dart';
import 'package:global_airsoft_app/src/features/auth/domain/models/auth_tokens.dart';

final class AuthSecurityInterceptor extends Interceptor {
  static const String _authorizationHeader = 'Authorization';
  static const String _bearerPrefix = 'Bearer ';
  static const String _handledCancellationMessage =
      'Auth security event handled.';

  static const Set<String> _publicRequestPaths = <String>{
    AuthApiPaths.signIn,
    AuthApiPaths.signInGoogle,
    AuthApiPaths.signUp,
    AuthApiPaths.signUpGoogle,
    AuthApiPaths.passwordRecovery,
  };

  static const String _accessTokenExpiredCode =
      'GlobalAirsoft:Auth:AccessTokenExpired';
  static const String _accessTokenInvalidCode =
      'GlobalAirsoft:Auth:AccessTokenInvalid';
  static const String _sessionInvalidCode = 'GlobalAirsoft:Auth:SessionInvalid';
  static const String _refreshTokenInvalidCode =
      'GlobalAirsoft:Auth:RefreshTokenInvalid';
  static const String _refreshTokenExpiredCode =
      'GlobalAirsoft:Auth:RefreshTokenExpired';
  static const String _sessionExpiredCode = 'GlobalAirsoft:Auth:SessionExpired';

  static const String _sessionEndedMessageKey =
      AppLocaleKeys.authSessionEndedForSecurityMessage;
  static const String _securityChangeMessageKey =
      AppLocaleKeys.authSecurityChangeDetectedMessage;
  static const String _permissionDeniedMessageKey =
      AppLocaleKeys.authPermissionDeniedMessage;
  static const String _tooManyAttemptsMessageKey =
      AppLocaleKeys.authTooManyAttemptsMessage;
  static const String _serverUnavailableMessageKey =
      AppLocaleKeys.authServerUnavailableMessage;

  AuthSecurityInterceptor({required Dio dio}) : _dio = dio;

  final Dio _dio;
  final AuthSecurityCoordinator _coordinator = AuthSecurityCoordinator.instance;
  final Set<RequestOptions> _retriedRequests = Set<RequestOptions>.identity();
  Future<AuthTokens?>? _refreshInFlight;
  int? _refreshInFlightSessionVersion;
  Completer<void>? _refreshBarrier;
  int? _refreshBarrierSessionVersion;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_wasRetryAttempted(options)) {
      handler.next(options);
      return;
    }

    if (_shouldSkipAuthorizationHeader(options.path)) {
      options.headers.remove(_authorizationHeader);
      handler.next(options);
      return;
    }

    await _waitForRefreshIfNeeded();

    final AuthTokens? tokens = await _readCurrentTokens();
    final String accessToken = tokens?.jwtToken.trim() ?? '';
    if (accessToken.isEmpty) {
      options.headers.remove(_authorizationHeader);
      handler.next(options);
      return;
    }

    options.headers[_authorizationHeader] = '$_bearerPrefix$accessToken';
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.error is AuthSecurityHandledException) {
      handler.next(err);
      return;
    }

    final Response<dynamic>? response = err.response;
    if (response == null) {
      handler.next(err);
      return;
    }

    final String path = err.requestOptions.path;
    if (_isPublicRequestPath(path)) {
      handler.next(err);
      return;
    }

    final Object? error = err.error;
    final ApiException apiException = error is ApiException
        ? error
        : ApiExceptionFormatter.toTypedException(err);

    if (_isRefreshPath(path)) {
      await _logoutAndReject(
        handler,
        fallbackMessageKey: _sessionEndedMessageKey,
        requestOptions: err.requestOptions,
        response: response,
        apiException: apiException,
      );
      return;
    }

    final int? statusCode = apiException.statusCode ?? response.statusCode;
    final String? code = apiException.code;
    final AuthTokens? currentTokens = await _readCurrentTokens();
    final String currentAccessToken = currentTokens?.jwtToken.trim() ?? '';
    final String requestAccessToken = _readRequestAccessToken(
      err.requestOptions,
    );

    if (_isAccessTokenExpired(statusCode: statusCode, code: code)) {
      if (_shouldRetryWithCurrentToken(
        currentAccessToken: currentAccessToken,
        requestAccessToken: requestAccessToken,
      )) {
        await _retryWithCurrentToken(
          requestOptions: err.requestOptions,
          currentAccessToken: currentAccessToken,
          handler: handler,
        );
        return;
      }

      if (_wasRetryAttempted(err.requestOptions)) {
        await _logoutAndReject(
          handler,
          fallbackMessageKey: _sessionEndedMessageKey,
          requestOptions: err.requestOptions,
          response: response,
          apiException: apiException,
        );
        return;
      }

      await _refreshAndRetry(
        originalError: err,
        apiException: apiException,
        handler: handler,
      );
      return;
    }

    if (_isSecurityInvalid(statusCode: statusCode, code: code)) {
      await _logoutAndReject(
        handler,
        fallbackMessageKey: _securityChangeMessageKey,
        requestOptions: err.requestOptions,
        response: response,
        apiException: apiException,
      );
      return;
    }

    if (_isForbidden(statusCode: statusCode, code: code)) {
      await _showMessageAndReject(
        handler,
        fallbackMessageKey: _permissionDeniedMessageKey,
        requestOptions: err.requestOptions,
        response: response,
        apiException: apiException,
      );
      return;
    }

    if (statusCode == 429) {
      await _showMessageAndReject(
        handler,
        fallbackMessageKey: _tooManyAttemptsMessageKey,
        requestOptions: err.requestOptions,
        response: response,
        apiException: apiException,
      );
      return;
    }

    if (statusCode != null && statusCode >= 500) {
      await _showMessageAndReject(
        handler,
        fallbackMessageKey: _serverUnavailableMessageKey,
        requestOptions: err.requestOptions,
        response: response,
        apiException: apiException,
      );
      return;
    }

    if (statusCode == 401) {
      await _logoutAndReject(
        handler,
        fallbackMessageKey: _securityChangeMessageKey,
        requestOptions: err.requestOptions,
        response: response,
        apiException: apiException,
      );
      return;
    }

    handler.next(err);
  }

  bool _shouldSkipAuthorizationHeader(String path) {
    return _publicRequestPaths.contains(path) || _isRefreshPath(path);
  }

  bool _isPublicRequestPath(String path) {
    return _publicRequestPaths.contains(path);
  }

  bool _isRefreshPath(String path) {
    return path == AuthApiPaths.refreshTokens;
  }

  bool _wasRetryAttempted(RequestOptions options) {
    return _retriedRequests.contains(options);
  }

  Future<void> _waitForRefreshIfNeeded() async {
    final Completer<void>? refreshBarrier = _refreshBarrier;
    if (refreshBarrier == null ||
        _refreshBarrierSessionVersion != _coordinator.sessionVersion) {
      return;
    }

    await refreshBarrier.future;
  }

  bool _beginRefreshWait(int sessionVersion) {
    final Completer<void>? existingBarrier = _refreshBarrier;
    if (existingBarrier != null) {
      if (_refreshBarrierSessionVersion == sessionVersion) {
        return false;
      }

      if (!existingBarrier.isCompleted) {
        existingBarrier.complete();
      }
    }

    _refreshBarrier = Completer<void>();
    _refreshBarrierSessionVersion = sessionVersion;
    return true;
  }

  void _endRefreshWait(int sessionVersion) {
    final Completer<void>? refreshBarrier = _refreshBarrier;
    if (refreshBarrier == null ||
        _refreshBarrierSessionVersion != sessionVersion) {
      return;
    }

    _refreshBarrier = null;
    _refreshBarrierSessionVersion = null;
    if (!refreshBarrier.isCompleted) {
      refreshBarrier.complete();
    }
  }

  String _readRequestAccessToken(RequestOptions options) {
    final Object? authorization = options.headers[_authorizationHeader];
    if (authorization is String && authorization.startsWith(_bearerPrefix)) {
      return authorization.substring(_bearerPrefix.length).trim();
    }

    return '';
  }

  bool _shouldRetryWithCurrentToken({
    required String currentAccessToken,
    required String requestAccessToken,
  }) {
    return currentAccessToken.isNotEmpty &&
        requestAccessToken.isNotEmpty &&
        currentAccessToken != requestAccessToken;
  }

  void _markRetryAttempted(RequestOptions options) {
    _retriedRequests.add(options);
  }

  void _clearRetryAttempted(RequestOptions options) {
    _retriedRequests.remove(options);
  }

  bool _isAccessTokenExpired({
    required int? statusCode,
    required String? code,
  }) {
    return code == _accessTokenExpiredCode ||
        (statusCode == 401 &&
            code != _accessTokenInvalidCode &&
            code != _sessionInvalidCode);
  }

  bool _isSecurityInvalid({required int? statusCode, required String? code}) {
    if (code == _accessTokenInvalidCode || code == _sessionInvalidCode) {
      return true;
    }

    return statusCode == 401 && code == null;
  }

  bool _isForbidden({required int? statusCode, required String? code}) {
    if (statusCode != 403) {
      return false;
    }

    return code != _sessionInvalidCode &&
        code != _accessTokenInvalidCode &&
        code != _refreshTokenInvalidCode &&
        code != _refreshTokenExpiredCode &&
        code != _sessionExpiredCode;
  }

  Future<void> _refreshAndRetry({
    required DioException originalError,
    required ApiException apiException,
    required ErrorInterceptorHandler handler,
  }) async {
    final RequestOptions options = originalError.requestOptions;
    final int sessionVersionAtStart = _coordinator.sessionVersion;
    final bool ownsRefreshWait = _beginRefreshWait(sessionVersionAtStart);

    try {
      final AuthTokens? currentTokens = await _readCurrentTokens();
      final String refreshToken = currentTokens?.refreshToken.trim() ?? '';
      if (refreshToken.isEmpty) {
        await _logoutAndReject(
          handler,
          fallbackMessageKey: _sessionEndedMessageKey,
          requestOptions: options,
          response: originalError.response!,
          apiException: apiException,
        );
        return;
      }

      final AuthTokens? refreshedTokens = await _refreshTokensSingleFlight(
        refreshToken: refreshToken,
        sessionVersion: sessionVersionAtStart,
      );
      if (sessionVersionAtStart != _coordinator.sessionVersion) {
        handler.reject(_handledDioExceptionFromOptions(options));
        return;
      }

      if (refreshedTokens == null) {
        await _logoutAndReject(
          handler,
          fallbackMessageKey: _sessionEndedMessageKey,
          requestOptions: options,
          response: originalError.response!,
          apiException: apiException,
        );
        return;
      }

      await _retryWithCurrentToken(
        requestOptions: options,
        currentAccessToken: refreshedTokens.jwtToken,
        handler: handler,
      );
    } on AuthSecurityHandledException catch (handledException) {
      await _logoutAndRejectWithException(
        handler,
        requestOptions: options,
        handledException: handledException,
      );
    } catch (error) {
      if (sessionVersionAtStart != _coordinator.sessionVersion) {
        handler.reject(_handledDioExceptionFromOptions(options));
        return;
      }

      final String fallbackMessage = await _coordinator.translateMessage(
        _sessionEndedMessageKey,
      );
      final AuthSecurityHandledException handledException =
          error is ApiException
          ? AuthSecurityHandledException.fromApiException(
              error,
              fallbackMessage: fallbackMessage.isNotEmpty
                  ? fallbackMessage
                  : _handledCancellationMessage,
              preferFallbackMessage: true,
            )
          : AuthSecurityHandledException(
              message: fallbackMessage.isNotEmpty
                  ? fallbackMessage
                  : _handledCancellationMessage,
            );

      await _logoutAndRejectWithException(
        handler,
        requestOptions: options,
        handledException: handledException,
      );
    } finally {
      if (ownsRefreshWait) {
        _endRefreshWait(sessionVersionAtStart);
      }
    }
  }

  Future<void> _logoutAndReject(
    ErrorInterceptorHandler handler, {
    required String fallbackMessageKey,
    required RequestOptions requestOptions,
    required Response<dynamic> response,
    required ApiException apiException,
  }) async {
    final AuthSecurityHandledException handledException =
        await _buildHandledException(
          apiException: apiException,
          fallbackMessageKey: fallbackMessageKey,
        );

    await _coordinator.clearSession();
    await _rejectHandledException(
      handler,
      requestOptions: requestOptions,
      response: response,
      handledException: handledException,
    );
  }

  Future<void> _logoutAndRejectWithException(
    ErrorInterceptorHandler handler, {
    required RequestOptions requestOptions,
    required AuthSecurityHandledException handledException,
  }) async {
    await _coordinator.clearSession();
    await _rejectHandledException(
      handler,
      requestOptions: requestOptions,
      response: null,
      handledException: handledException,
    );
  }

  Future<void> _showMessageAndReject(
    ErrorInterceptorHandler handler, {
    required String fallbackMessageKey,
    required RequestOptions requestOptions,
    required Response<dynamic> response,
    required ApiException apiException,
  }) async {
    final AuthSecurityHandledException handledException =
        await _buildHandledException(
          apiException: apiException,
          fallbackMessageKey: fallbackMessageKey,
        );

    await _rejectHandledException(
      handler,
      requestOptions: requestOptions,
      response: response,
      handledException: handledException,
    );
  }

  Future<AuthSecurityHandledException> _buildHandledException({
    required ApiException apiException,
    required String fallbackMessageKey,
  }) async {
    final String fallbackMessage = await _coordinator.translateMessage(
      fallbackMessageKey,
    );

    return AuthSecurityHandledException.fromApiException(
      apiException,
      fallbackMessage: fallbackMessage.isNotEmpty
          ? fallbackMessage
          : _handledCancellationMessage,
      preferFallbackMessage: true,
    );
  }

  Future<void> _rejectHandledException(
    ErrorInterceptorHandler handler, {
    required RequestOptions requestOptions,
    required Response<dynamic>? response,
    required AuthSecurityHandledException handledException,
  }) async {
    final String message = handledException.message.trim();
    if (message.isNotEmpty) {
      await _coordinator.showMessage(message, source: handledException);
    }

    handler.reject(
      DioException(
        requestOptions: requestOptions,
        response: response,
        type: DioExceptionType.cancel,
        error: handledException,
        message: message.isNotEmpty ? message : _handledCancellationMessage,
      ),
    );
  }

  Future<void> _retryWithCurrentToken({
    required RequestOptions requestOptions,
    required String currentAccessToken,
    required ErrorInterceptorHandler handler,
  }) async {
    _markRetryAttempted(requestOptions);
    requestOptions.headers[_authorizationHeader] =
        '$_bearerPrefix$currentAccessToken';

    try {
      final Response<dynamic> retryResponse = await _dio.fetch<dynamic>(
        requestOptions,
      );
      handler.resolve(retryResponse);
    } catch (error) {
      handler.reject(_wrapAsDioException(requestOptions, error));
    } finally {
      _clearRetryAttempted(requestOptions);
    }
  }

  DioException _handledDioExceptionFromOptions(RequestOptions requestOptions) {
    return DioException(
      requestOptions: requestOptions,
      type: DioExceptionType.cancel,
      error: const AuthSecurityHandledException(
        message: _handledCancellationMessage,
      ),
      message: _handledCancellationMessage,
    );
  }

  Future<AuthTokens?> _refreshTokensSingleFlight({
    required String refreshToken,
    required int sessionVersion,
  }) {
    final Future<AuthTokens?>? ongoing = _refreshInFlight;
    if (ongoing != null && _refreshInFlightSessionVersion == sessionVersion) {
      return ongoing;
    }

    final Future<AuthTokens?> inFlight = _performRefreshTokens(
      refreshToken: refreshToken,
      sessionVersion: sessionVersion,
    );
    _refreshInFlight = inFlight;
    _refreshInFlightSessionVersion = sessionVersion;

    inFlight
        .whenComplete(() {
          if (identical(_refreshInFlight, inFlight)) {
            _refreshInFlight = null;
            _refreshInFlightSessionVersion = null;
          }
        })
        .catchError((Object _) => null);

    return inFlight;
  }

  Future<AuthTokens?> _performRefreshTokens({
    required String refreshToken,
    required int sessionVersion,
  }) async {
    try {
      final AuthTokens refreshedTokens = await _coordinator.refreshTokens(
        refreshToken,
      );

      if (sessionVersion != _coordinator.sessionVersion) {
        return null;
      }

      await _coordinator.saveTokens(refreshedTokens);
      return refreshedTokens;
    } on AuthSecurityHandledException {
      rethrow;
    } on ApiException catch (error) {
      final String fallbackMessage = await _coordinator.translateMessage(
        _sessionEndedMessageKey,
      );
      throw AuthSecurityHandledException.fromApiException(
        error,
        fallbackMessage: fallbackMessage.isNotEmpty
            ? fallbackMessage
            : _handledCancellationMessage,
        preferFallbackMessage: true,
      );
    } catch (_) {
      final String fallbackMessage = await _coordinator.translateMessage(
        _sessionEndedMessageKey,
      );
      throw AuthSecurityHandledException(
        message: fallbackMessage.isNotEmpty
            ? fallbackMessage
            : _handledCancellationMessage,
      );
    }
  }

  DioException _wrapAsDioException(RequestOptions options, Object error) {
    if (error is DioException) {
      return error;
    }

    return DioException(
      requestOptions: options,
      type: DioExceptionType.unknown,
      error: error,
      message: error.toString(),
    );
  }

  Future<AuthTokens?> _readCurrentTokens() {
    if (_coordinator.hasCachedTokens) {
      return Future<AuthTokens?>.value(_coordinator.cachedTokens);
    }

    return _coordinator.readTokens();
  }
}

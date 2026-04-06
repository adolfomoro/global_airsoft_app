import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FcmPushTokenService {
  FcmPushTokenService({FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;
  final StreamController<String> _tokenChangesController =
      StreamController<String>.broadcast();

  StreamSubscription<String>? _refreshSubscription;
  Future<String>? _initializationFuture;
  String _currentToken = '';
  bool _initialized = false;

  Stream<String> get tokenChanges => _tokenChangesController.stream;

  Future<AuthorizationStatus> getAuthorizationStatus() async {
    try {
      await _ensureFirebaseInitialized();
      final settings = await _messaging.getNotificationSettings();
      return settings.authorizationStatus;
    } catch (e) {
      _debugLog('Failed to get notification status: $e');
      return AuthorizationStatus.notDetermined;
    }
  }

  Future<String> initialize() async {
    if (_initialized && _currentToken.isNotEmpty) {
      return _currentToken;
    }

    final inFlight = _initializationFuture;
    if (inFlight != null) {
      return inFlight;
    }

    final initFuture = _initializeInternal();
    _initializationFuture = initFuture;

    try {
      return await initFuture;
    } finally {
      if (identical(_initializationFuture, initFuture)) {
        _initializationFuture = null;
      }
    }
  }

  Future<String> initializeTokenWithoutPermission() async {
    if (_currentToken.isNotEmpty) {
      return _currentToken;
    }

    try {
      await _ensureFirebaseInitialized();
      _currentToken = (await _messaging.getToken()) ?? '';
      _ensureRefreshSubscription();
    } catch (e) {
      _debugLog('Failed to get FCM token without permission: $e');
    }

    return _currentToken;
  }

  Future<String> _initializeInternal() async {
    if (_initialized) {
      return _currentToken;
    }

    try {
      await _ensureFirebaseInitialized();
      await _requestPermissionsIfNeeded();

      _currentToken = (await _messaging.getToken()) ?? '';
      _ensureRefreshSubscription();
      _initialized = true;
    } catch (e) {
      _debugLog('FCM unavailable on this environment: $e');
      _initialized = true;
    }

    return _currentToken;
  }

  Future<void> _ensureFirebaseInitialized() async {
    if (Firebase.apps.isNotEmpty) {
      return;
    }
    await Firebase.initializeApp();
  }

  Future<void> _requestPermissionsIfNeeded() async {
    await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  void _ensureRefreshSubscription() {
    if (_refreshSubscription != null) {
      return;
    }

    _refreshSubscription = _messaging.onTokenRefresh.listen((newToken) {
      if (newToken.isEmpty || newToken == _currentToken) {
        return;
      }
      _currentToken = newToken;
      if (!_tokenChangesController.isClosed) {
        _tokenChangesController.add(newToken);
      }
    });
  }

  String getCurrentToken() => _currentToken;

  Future<void> dispose() async {
    await _refreshSubscription?.cancel();
    await _tokenChangesController.close();
  }

  void _debugLog(String message) {
    assert(() {
      debugPrint(message);
      return true;
    }());
  }
}

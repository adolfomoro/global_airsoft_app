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

  Future<String> initialize() async {
    if (_initialized) {
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

  Future<String> _initializeInternal() async {
    if (_initialized) {
      return _currentToken;
    }

    try {
      await _ensureFirebaseInitialized();
      await _requestPermissionsIfNeeded();

      _currentToken = (await _messaging.getToken()) ?? '';
      _refreshSubscription = _messaging.onTokenRefresh.listen((newToken) {
        if (newToken.isEmpty || newToken == _currentToken) {
          return;
        }
        _currentToken = newToken;
        if (!_tokenChangesController.isClosed) {
          _tokenChangesController.add(newToken);
        }
      });
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
    if (defaultTargetPlatform != TargetPlatform.iOS &&
        defaultTargetPlatform != TargetPlatform.macOS) {
      return;
    }

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

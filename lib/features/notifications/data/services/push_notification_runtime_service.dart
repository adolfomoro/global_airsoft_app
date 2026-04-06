import 'dart:async';
import 'dart:io' as io;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../domain/models/push_notification_tap_event.dart';
import 'push_notification_payload_translator.dart';

const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
  'global_airsoft_general',
  'Notificações Gerais',
  description: 'Canal geral para notificações do app.',
  importance: Importance.high,
);

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
}

class PushNotificationRuntimeService {
  PushNotificationRuntimeService({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
    PushNotificationPayloadTranslator? translator,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       _localNotifications =
           localNotifications ?? FlutterLocalNotificationsPlugin(),
       _translator = translator ?? const PushNotificationPayloadTranslator();

  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final PushNotificationPayloadTranslator _translator;

  final StreamController<PushNotificationTapEvent> _tapEventsController =
      StreamController<PushNotificationTapEvent>.broadcast();

  Future<void>? _initializeFuture;
  bool _initialized = false;

  Stream<PushNotificationTapEvent> get tapEvents => _tapEventsController.stream;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    final inFlight = _initializeFuture;
    if (inFlight != null) {
      return inFlight;
    }

    final initFuture = _initializeInternal();
    _initializeFuture = initFuture;

    try {
      await initFuture;
    } finally {
      if (identical(_initializeFuture, initFuture)) {
        _initializeFuture = null;
      }
    }
  }

  Future<void> _initializeInternal() async {
    if (_initialized) {
      return;
    }

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      await _configureLocalNotifications();
      await _configureForegroundHandling();
      await _configureTapHandling();

      _initialized = true;
    } catch (e) {
      _debugLog('Push runtime initialization failed: $e');
      _initialized = true;
    }
  }

  Future<void> _configureLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        macOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = _tryDecodePayloadString(response.payload);
        _tapEventsController.add(
          PushNotificationTapEvent(
            messageId: payload['messageId']?.toString() ?? '',
            payload: payload,
            openedFromTerminated: false,
          ),
        );
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidChannel);
  }

  Future<void> _configureForegroundHandling() async {
    if (io.Platform.isIOS) {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    FirebaseMessaging.onMessage.listen((message) async {
      final parsed = _translator.translate(message);

      await _localNotifications.show(
        parsed.messageId.hashCode,
        parsed.title,
        parsed.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
          macOS: DarwinNotificationDetails(),
        ),
        payload: _encodePayload(parsed.payload, parsed.messageId),
      );
    });
  }

  Future<void> _configureTapHandling() async {
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final parsed = _translator.translate(message);
      _tapEventsController.add(
        PushNotificationTapEvent(
          messageId: parsed.messageId,
          payload: parsed.payload,
          openedFromTerminated: false,
        ),
      );
    });

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage == null) {
      return;
    }

    final parsed = _translator.translate(initialMessage);
    _tapEventsController.add(
      PushNotificationTapEvent(
        messageId: parsed.messageId,
        payload: parsed.payload,
        openedFromTerminated: true,
      ),
    );
  }

  Map<String, dynamic> _tryDecodePayloadString(String? rawPayload) {
    if (rawPayload == null || rawPayload.isEmpty) {
      return {};
    }

    final parts = rawPayload.split('|__|');
    if (parts.length != 2) {
      return {};
    }

    final map = <String, dynamic>{'messageId': parts.first};
    final keyValues = parts.last.split('&');
    for (final entry in keyValues) {
      final index = entry.indexOf('=');
      if (index <= 0) {
        continue;
      }
      final key = Uri.decodeComponent(entry.substring(0, index));
      final value = Uri.decodeComponent(entry.substring(index + 1));
      map[key] = value;
    }

    return map;
  }

  String _encodePayload(Map<String, dynamic> payload, String messageId) {
    if (payload.isEmpty) {
      return messageId;
    }

    final encoded = payload.entries
        .map(
          (entry) =>
              '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value.toString())}',
        )
        .join('&');

    return '$messageId|__|$encoded';
  }

  Future<void> dispose() async {
    await _tapEventsController.close();
  }

  void _debugLog(String message) {
    assert(() {
      debugPrint(message);
      return true;
    }());
  }
}

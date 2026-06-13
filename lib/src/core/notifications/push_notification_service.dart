import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localization_service.dart';
import 'package:global_airsoft_app/src/core/logging/app_logger.dart';

const String messagesNotificationChannelId = 'messages_channel';
const String socialNotificationChannelId = 'social_channel';
const String othersNotificationChannelId = 'others_channel';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (error, stackTrace) {
    AppLogger.instance.error(
      'Firebase background handler initialization failed.',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

final class PushNotificationService {
  PushNotificationService({
    required AppLogger logger,
    required AppLocalizationService localizationService,
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
  }) : _logger = logger,
       _localizationService = localizationService,
       _messaging = messaging,
       _localNotifications =
           localNotifications ?? FlutterLocalNotificationsPlugin();

  static bool _backgroundHandlerRegistered = false;

  final AppLogger _logger;
  final AppLocalizationService _localizationService;
  FirebaseMessaging? _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;

  bool _initialized = false;
  AndroidNotificationChannel? _messagesChannel;
  AndroidNotificationChannel? _socialChannel;
  AndroidNotificationChannel? _othersChannel;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;

  static void registerBackgroundHandler() {
    if (_backgroundHandlerRegistered) {
      return;
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    _backgroundHandlerRegistered = true;
  }

  Future<void> initialize({
    required Future<void> Function(String token) onTokenUpdated,
  }) async {
    if (_initialized) {
      return;
    }

    await _initializeFirebase();
    final FirebaseMessaging messaging = await _getMessaging();
    await _initializeLocalNotifications();
    await _createAndroidChannels();
    await _configureForegroundPresentation(messaging);
    await _syncCurrentToken(messaging, onTokenUpdated);

    _tokenRefreshSubscription = messaging.onTokenRefresh.listen((String token) {
      unawaited(onTokenUpdated(token));
    });

    _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
    );

    _initialized = true;
  }

  Future<AuthorizationStatus> getAuthorizationStatus() async {
    final FirebaseMessaging messaging = await _getMessaging();
    final NotificationSettings settings = await messaging
        .getNotificationSettings();
    return settings.authorizationStatus;
  }

  Future<NotificationSettings> requestPermissions() async {
    final FirebaseMessaging messaging = await _getMessaging();
    final NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    await _logPermissionStatus(settings);
    return settings;
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    await _foregroundMessageSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _foregroundMessageSubscription = null;
    _initialized = false;
  }

  Future<void> _initializeFirebase() async {
    if (Firebase.apps.isNotEmpty) {
      return;
    }

    await Firebase.initializeApp();
  }

  Future<FirebaseMessaging> _getMessaging() async {
    await _initializeFirebase();
    return _messaging ??= FirebaseMessaging.instance;
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInitializationSettings =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: androidInitializationSettings,
          iOS: iosInitializationSettings,
        );

    await _localNotifications.initialize(settings: initializationSettings);
  }

  Future<void> _createAndroidChannels() async {
    final AndroidNotificationChannel messagesChannel =
        await _buildMessagesChannel();
    final AndroidNotificationChannel socialChannel =
        await _buildSocialChannel();
    final AndroidNotificationChannel othersChannel =
        await _buildOthersChannel();

    _messagesChannel = messagesChannel;
    _socialChannel = socialChannel;
    _othersChannel = othersChannel;

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidImplementation == null) {
      return;
    }

    await _recreateAndroidChannel(
      implementation: androidImplementation,
      channel: messagesChannel,
    );
    await _recreateAndroidChannel(
      implementation: androidImplementation,
      channel: socialChannel,
    );
    await _recreateAndroidChannel(
      implementation: androidImplementation,
      channel: othersChannel,
    );
  }

  Future<void> _recreateAndroidChannel({
    required AndroidFlutterLocalNotificationsPlugin implementation,
    required AndroidNotificationChannel channel,
  }) async {
    try {
      await implementation.deleteNotificationChannel(channelId: channel.id);
    } catch (error, stackTrace) {
      _logger.error(
        'Failed to delete existing notification channel. Proceeding with recreate.',
        error: error,
        stackTrace: stackTrace,
      );
    }

    await implementation.createNotificationChannel(channel);
  }

  Future<void> _configureForegroundPresentation(
    FirebaseMessaging messaging,
  ) async {
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _logPermissionStatus(NotificationSettings settings) async {
    _logger.info(
      await _localizationService.trArgs(
        AppLocaleKeys.notificationPermissionStatus,
        args: <String, Object?>{'status': settings.authorizationStatus.name},
      ),
    );
  }

  Future<void> _syncCurrentToken(
    FirebaseMessaging messaging,
    Future<void> Function(String token) onTokenUpdated,
  ) async {
    final String? token = await messaging.getToken();
    if (token == null || token.trim().isEmpty) {
      return;
    }

    await onTokenUpdated(token);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final String? title =
        message.notification?.title ?? _trimmedValue(message.data['title']);
    final String? body =
        message.notification?.body ?? _trimmedValue(message.data['body']);

    if (title == null && body == null) {
      return;
    }

    final AndroidNotificationChannel channel = _channelForMessage(message);

    try {
      await _localNotifications.show(
        id: message.hashCode,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: jsonEncode(message.data),
      );
    } catch (error, stackTrace) {
      _logger.error(
        'Failed to show foreground notification.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  AndroidNotificationChannel _channelForMessage(RemoteMessage message) {
    final String? source = _resolveChannelSourceFromFirebasePayload(message);

    if (source == null) {
      return _fallbackChannel();
    }

    final String normalized = source.toLowerCase();
    if (normalized == messagesNotificationChannelId ||
        normalized.contains('message') ||
        normalized.contains('chat')) {
      return _messagesChannel ?? _fallbackChannel();
    }

    if (normalized == socialNotificationChannelId ||
        normalized.contains('social') ||
        normalized.contains('friend')) {
      return _socialChannel ?? _fallbackChannel();
    }

    return _fallbackChannel();
  }

  AndroidNotificationChannel _fallbackChannel() {
    return _othersChannel ??
        _socialChannel ??
        _messagesChannel ??
        const AndroidNotificationChannel(
          othersNotificationChannelId,
          othersNotificationChannelId,
          description: othersNotificationChannelId,
          importance: Importance.defaultImportance,
        );
  }

  String? _resolveChannelSourceFromFirebasePayload(RemoteMessage message) {
    final String? androidNotificationChannelId = _trimmedValue(
      message.notification?.android?.channelId,
    );
    if (androidNotificationChannelId != null) {
      return androidNotificationChannelId;
    }

    return _trimmedValue(message.data['channel_id']) ??
        _trimmedValue(message.data['channel']) ??
        _trimmedValue(message.data['android_channel_id']) ??
        _trimmedValue(message.data['type']);
  }

  Future<AndroidNotificationChannel> _buildMessagesChannel() async {
    return AndroidNotificationChannel(
      messagesNotificationChannelId,
      await _localizationService.tr(AppLocaleKeys.notificationChannelMessages),
      description: await _localizationService.tr(
        AppLocaleKeys.notificationChannelMessagesDescription,
      ),
      importance: Importance.max,
    );
  }

  Future<AndroidNotificationChannel> _buildSocialChannel() async {
    return AndroidNotificationChannel(
      socialNotificationChannelId,
      await _localizationService.tr(AppLocaleKeys.notificationChannelSocial),
      description: await _localizationService.tr(
        AppLocaleKeys.notificationChannelSocialDescription,
      ),
      importance: Importance.max,
    );
  }

  Future<AndroidNotificationChannel> _buildOthersChannel() async {
    return AndroidNotificationChannel(
      othersNotificationChannelId,
      await _localizationService.tr(AppLocaleKeys.notificationChannelOthers),
      description: await _localizationService.tr(
        AppLocaleKeys.notificationChannelOthersDescription,
      ),
      importance: Importance.max,
    );
  }

  String? _trimmedValue(Object? value) {
    if (value is! String) {
      return null;
    }

    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

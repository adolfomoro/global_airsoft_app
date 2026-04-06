import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../../domain/models/parsed_push_notification.dart';

class PushNotificationPayloadTranslator {
  const PushNotificationPayloadTranslator();

  ParsedPushNotification translate(RemoteMessage message) {
    final mergedPayload = _mergePayload(message);

    final title = _stringValue(
      mergedPayload['title'],
      fallback: message.notification?.title ?? 'Global Airsoft',
    );
    final body = _stringValue(
      mergedPayload['body'],
      fallback: message.notification?.body ?? 'Você recebeu uma nova atualização.',
    );

    return ParsedPushNotification(
      messageId: message.messageId ?? _buildMessageId(message),
      title: title,
      body: body,
      payload: mergedPayload,
      receivedAt: message.sentTime ?? DateTime.now(),
    );
  }

  Map<String, dynamic> _mergePayload(RemoteMessage message) {
    final result = <String, dynamic>{};

    if (message.data.isNotEmpty) {
      result.addAll(message.data);
    }

    final candidates = <dynamic>[
      message.data['payload'],
      message.data['notification'],
      message.data['json'],
      message.notification?.body,
    ];

    for (final candidate in candidates) {
      final decoded = _tryDecodeJsonMap(candidate);
      if (decoded != null) {
        result.addAll(decoded);
      }
    }

    return result;
  }

  Map<String, dynamic>? _tryDecodeJsonMap(dynamic source) {
    if (source is Map<String, dynamic>) {
      return source;
    }

    if (source is! String || source.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(source);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  String _stringValue(dynamic value, {required String fallback}) {
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    return fallback;
  }

  String _buildMessageId(RemoteMessage message) {
    final millis = (message.sentTime ?? DateTime.now()).millisecondsSinceEpoch;
    return 'push_$millis';
  }
}

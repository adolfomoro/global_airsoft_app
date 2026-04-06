class ParsedPushNotification {
  const ParsedPushNotification({
    required this.messageId,
    required this.title,
    required this.body,
    required this.payload,
    required this.receivedAt,
  });

  final String messageId;
  final String title;
  final String body;
  final Map<String, dynamic> payload;
  final DateTime receivedAt;
}

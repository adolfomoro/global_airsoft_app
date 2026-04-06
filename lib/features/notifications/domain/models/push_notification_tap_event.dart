class PushNotificationTapEvent {
  const PushNotificationTapEvent({
    required this.messageId,
    required this.payload,
    required this.openedFromTerminated,
  });

  final String messageId;
  final Map<String, dynamic> payload;
  final bool openedFromTerminated;
}

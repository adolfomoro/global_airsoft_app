enum PushNotificationType {
  unknown(0),
  fcm(1),
  apns(2),
  webPush(3);

  const PushNotificationType(this.value);

  final int value;
}

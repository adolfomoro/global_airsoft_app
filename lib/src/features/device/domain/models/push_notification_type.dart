enum PushNotificationType {
  unknown(0),
  fcm(1),
  apns(2),
  webPush(3);

  const PushNotificationType(this.value);

  final int value;

  factory PushNotificationType.fromValue(int value) {
    return PushNotificationType.values.firstWhere(
      (PushNotificationType type) => type.value == value,
      orElse: () => PushNotificationType.unknown,
    );
  }
}

/// Push notification platform type
enum PushNotificationType {
  unknown(0),
  fcm(1),
  apns(2),
  webPush(3);

  final int value;
  const PushNotificationType(this.value);

  factory PushNotificationType.fromValue(int value) {
    return PushNotificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => PushNotificationType.unknown,
    );
  }
}

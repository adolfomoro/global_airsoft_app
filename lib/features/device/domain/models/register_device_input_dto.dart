import 'push_notification_type.dart';

class RegisterDeviceInputDto {
  RegisterDeviceInputDto({
    this.deviceId,
    required this.platform,
    required this.deviceType,
    required this.appVersion,
    this.deviceModel,
    required this.pushNotificationToken,
    required this.pushNotificationType,
  });

  final String? deviceId;
  final String platform;
  final String deviceType;
  final String appVersion;
  final String? deviceModel;
  final String pushNotificationToken;
  final PushNotificationType pushNotificationType;

  Map<String, dynamic> toJson() {
    return {
      if (deviceId != null) 'deviceId': deviceId,
      'platform': platform,
      'deviceType': deviceType,
      'appVersion': appVersion,
      if (deviceModel != null) 'deviceModel': deviceModel,
      'pushNotificationToken': pushNotificationToken,
      'pushNotificationType': pushNotificationType.value,
    };
  }

  @override
  String toString() =>
      'RegisterDeviceInputDto(deviceId: $deviceId, platform: $platform, '
      'deviceType: $deviceType, appVersion: $appVersion, '
      'deviceModel: $deviceModel, pushNotificationType: $pushNotificationType)';
}

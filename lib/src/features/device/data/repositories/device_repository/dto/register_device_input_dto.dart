import 'package:global_airsoft_app/src/features/device/domain/models/push_notification_type.dart';

final class RegisterDeviceInputDto {
  RegisterDeviceInputDto({
    required this.platform,
    required this.deviceType,
    required this.appVersion,
    required this.pushNotificationToken,
    required this.pushNotificationType,
    this.deviceId,
    this.deviceModel,
  });

  final String? deviceId;
  final String platform;
  final String deviceType;
  final String appVersion;
  final String? deviceModel;
  final String pushNotificationToken;
  final PushNotificationType pushNotificationType;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (deviceId != null) 'deviceId': deviceId,
      'platform': platform,
      'deviceType': deviceType,
      'appVersion': appVersion,
      if (deviceModel != null) 'deviceModel': deviceModel,
      'pushNotificationToken': pushNotificationToken,
      'pushNotificationType': pushNotificationType.value,
    };
  }
}

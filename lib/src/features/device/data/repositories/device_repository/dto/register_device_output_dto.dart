final class RegisterDeviceOutputDto {
  RegisterDeviceOutputDto({required this.deviceId});

  final String deviceId;

  factory RegisterDeviceOutputDto.fromJson(Map<String, dynamic> json) {
    return RegisterDeviceOutputDto(deviceId: json['deviceId'] as String);
  }
}

/// Output DTO for device registration
class RegisterDeviceOutputDto {
  RegisterDeviceOutputDto({required this.deviceId});

  factory RegisterDeviceOutputDto.fromJson(Map<String, dynamic> json) {
    return RegisterDeviceOutputDto(deviceId: json['deviceId'] as String);
  }

  final String deviceId;

  @override
  String toString() => 'RegisterDeviceOutputDto(deviceId: $deviceId)';
}

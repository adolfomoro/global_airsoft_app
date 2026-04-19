final class DeviceStorageSnapshot {
  const DeviceStorageSnapshot({
    required this.deviceId,
    required this.lastPlatform,
    required this.lastDeviceType,
    required this.lastAppVersion,
    required this.lastDeviceModel,
    required this.lastPushToken,
  });

  const DeviceStorageSnapshot.empty()
    : deviceId = null,
      lastPlatform = null,
      lastDeviceType = null,
      lastAppVersion = null,
      lastDeviceModel = null,
      lastPushToken = null;

  final String? deviceId;
  final String? lastPlatform;
  final String? lastDeviceType;
  final String? lastAppVersion;
  final String? lastDeviceModel;
  final String? lastPushToken;

  factory DeviceStorageSnapshot.fromJson(Map<String, dynamic> json) {
    return DeviceStorageSnapshot(
      deviceId: _readNullableString(json['deviceId']),
      lastPlatform: _readNullableString(json['lastPlatform']),
      lastDeviceType: _readNullableString(json['lastDeviceType']),
      lastAppVersion: _readNullableString(json['lastAppVersion']),
      lastDeviceModel: _readNullableString(json['lastDeviceModel']),
      lastPushToken: _readNullableString(json['lastPushToken']),
    );
  }

  Map<String, String> toJson() {
    final Map<String, String> result = <String, String>{};

    if (deviceId?.isNotEmpty ?? false) {
      result['deviceId'] = deviceId!;
    }
    if (lastPlatform?.isNotEmpty ?? false) {
      result['lastPlatform'] = lastPlatform!;
    }
    if (lastDeviceType?.isNotEmpty ?? false) {
      result['lastDeviceType'] = lastDeviceType!;
    }
    if (lastAppVersion?.isNotEmpty ?? false) {
      result['lastAppVersion'] = lastAppVersion!;
    }
    if (lastDeviceModel?.isNotEmpty ?? false) {
      result['lastDeviceModel'] = lastDeviceModel!;
    }
    if (lastPushToken?.isNotEmpty ?? false) {
      result['lastPushToken'] = lastPushToken!;
    }

    return result;
  }

  static String? _readNullableString(Object? value) {
    if (value is! String) {
      return null;
    }

    final String normalized = value.trim();
    if (normalized.isEmpty) {
      return null;
    }
    return normalized;
  }
}

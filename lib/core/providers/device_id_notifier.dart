import 'package:flutter_riverpod/flutter_riverpod.dart';

class DeviceIdNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setDeviceId(String deviceId) {
    state = deviceId;
  }

  String getDeviceId() => state;

  bool isLoaded() => state.isNotEmpty;
}

final deviceIdNotifierProvider = NotifierProvider<DeviceIdNotifier, String>(
  DeviceIdNotifier.new,
);

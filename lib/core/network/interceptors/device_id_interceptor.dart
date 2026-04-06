import 'package:dio/dio.dart';

class DeviceIdInterceptor extends Interceptor {
  DeviceIdInterceptor(this.getDeviceId);

  final String Function() getDeviceId;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final deviceId = getDeviceId();
    if (deviceId.isNotEmpty) {
      options.headers['X-Device-Id'] = deviceId;
    }
    super.onRequest(options, handler);
  }
}

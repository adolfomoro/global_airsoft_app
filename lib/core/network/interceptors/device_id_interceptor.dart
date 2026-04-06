import 'package:dio/dio.dart';

class DeviceIdInterceptor extends Interceptor {
  DeviceIdInterceptor(this.deviceId);

  final String deviceId;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (deviceId.isNotEmpty) {
      options.headers['X-Device-Id'] = deviceId;
    }
    super.onRequest(options, handler);
  }
}

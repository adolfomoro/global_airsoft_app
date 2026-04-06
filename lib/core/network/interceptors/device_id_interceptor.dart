import 'package:dio/dio.dart';

class DeviceIdInterceptor extends Interceptor {
  DeviceIdInterceptor({
    required this.getDeviceId,
    required this.ensureDeviceSynced,
    this.skipPaths = const <String>{},
  });

  final String Function() getDeviceId;
  final Future<bool> Function() ensureDeviceSynced;
  final Set<String> skipPaths;

  bool _shouldSkip(RequestOptions options) {
    final path = options.path;
    return skipPaths.contains(path);
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_shouldSkip(options)) {
      final synced = await ensureDeviceSynced();
      if (!synced) {
        handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.cancel,
            error: 'Device sync required before request execution',
            message: 'Device sync required before request execution',
          ),
        );
        return;
      }
    }

    final deviceId = getDeviceId();
    if (deviceId.isNotEmpty) {
      options.headers['X-Device-Id'] = deviceId;
    }

    handler.next(options);
  }
}

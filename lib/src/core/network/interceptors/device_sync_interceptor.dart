import 'package:dio/dio.dart';

final class DeviceSyncInterceptor extends Interceptor {
  DeviceSyncInterceptor({
    required String? Function() getDeviceId,
    required Future<bool> Function() ensureDeviceSynced,
    this.skipPaths = const <String>{},
  }) : _getDeviceId = getDeviceId,
       _ensureDeviceSynced = ensureDeviceSynced;

  final String? Function() _getDeviceId;
  final Future<bool> Function() _ensureDeviceSynced;
  final Set<String> skipPaths;

  bool _shouldSkip(RequestOptions options) {
    return skipPaths.contains(options.path);
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_shouldSkip(options)) {
      final bool synced = await _ensureDeviceSynced();
      if (!synced) {
        handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.cancel,
            message: 'Device sync required before request execution.',
            error: 'Device sync required before request execution.',
          ),
        );
        return;
      }
    }

    final String? deviceId = _getDeviceId();
    if (deviceId != null && deviceId.isNotEmpty) {
      options.headers['X-Device-Id'] = deviceId;
    }

    handler.next(options);
  }
}

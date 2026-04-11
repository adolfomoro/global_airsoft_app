import 'package:dio/dio.dart';

final class DeviceSyncInterceptor extends Interceptor {
  static const String _deviceSyncRequiredMessage =
      'Device sync required before request execution.';

  DeviceSyncInterceptor({
    required String? Function() getDeviceId,
    required Future<bool> Function() ensureDeviceSynced,
    this.skipPaths = const <String>{},
  }) : _getDeviceId = getDeviceId,
       _ensureDeviceSynced = ensureDeviceSynced;

  final String? Function() _getDeviceId;
  final Future<bool> Function() _ensureDeviceSynced;
  final Set<String> skipPaths;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!skipPaths.contains(options.path)) {
      final bool synced = await _ensureDeviceSynced();
      if (!synced) {
        handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.cancel,
            message: _deviceSyncRequiredMessage,
            error: _deviceSyncRequiredMessage,
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

import 'package:dio/dio.dart';
import 'package:global_airsoft_app/src/core/network/api_exception.dart';

final class DeviceSyncInterceptor extends Interceptor {
  static const String _deviceIdHeader = 'X-Device-Id';

  DeviceSyncInterceptor({
    required String? Function() getDeviceId,
    required Future<bool> Function() ensureDeviceSynced,
    required Future<String> Function() deviceSyncRequiredMessageResolver,
    this.skipPaths = const <String>{},
  }) : _getDeviceId = getDeviceId,
       _ensureDeviceSynced = ensureDeviceSynced,
       _deviceSyncRequiredMessageResolver = deviceSyncRequiredMessageResolver;

  final String? Function() _getDeviceId;
  final Future<bool> Function() _ensureDeviceSynced;
  final Future<String> Function() _deviceSyncRequiredMessageResolver;
  final Set<String> skipPaths;

  bool _isSkippablePath(String path) {
    return skipPaths.contains(path);
  }

  void _attachDeviceHeader(RequestOptions options) {
    final String? deviceId = _getDeviceId();
    if (deviceId != null && deviceId.isNotEmpty) {
      options.headers[_deviceIdHeader] = deviceId;
    }
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isSkippablePath(options.path)) {
      final bool synced = await _ensureDeviceSynced();
      if (!synced) {
        final String localizedMessage =
            await _deviceSyncRequiredMessageResolver();
        final String message = localizedMessage.trim().isNotEmpty
            ? localizedMessage.trim()
            : ApiException.defaultBadResponseFallbackMessage;
        handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.cancel,
            message: message,
            error: message,
          ),
        );
        return;
      }
    }

    _attachDeviceHeader(options);

    handler.next(options);
  }
}

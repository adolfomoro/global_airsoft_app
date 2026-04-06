import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'interceptors/device_id_interceptor.dart';

class DioService {
  DioService({
    required AppConfig config,
    required String Function() getDeviceId,
    required Future<bool> Function() ensureDeviceSynced,
    Set<String> skipDeviceSyncPaths = const <String>{},
    Dio? dio,
    List<Interceptor> additionalInterceptors = const [],
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: config.normalizedApiBaseUrl,
               headers: const {
                 'Accept': 'application/json',
                 'Content-Type': 'application/json',
               },
               connectTimeout: config.connectTimeout,
               receiveTimeout: config.receiveTimeout,
               sendTimeout: config.sendTimeout,
               responseType: ResponseType.json,
             ),
           ) {
    _dio.options.baseUrl =
        '${config.normalizedApiBaseUrl}${config.apiPrefix}';
    _dio.interceptors.add(
      DeviceIdInterceptor(
        getDeviceId: getDeviceId,
        ensureDeviceSynced: ensureDeviceSynced,
        skipPaths: skipDeviceSyncPaths,
      ),
    );
    _dio.interceptors.addAll(additionalInterceptors);

    if (config.enableNetworkLogs && !config.isProduction) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: false,
          responseBody: false,
        ),
      );
    }
  }

  final Dio _dio;

  Dio get client => _dio;
}
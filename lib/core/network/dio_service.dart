import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'interceptors/device_id_interceptor.dart';

class DioService {
  DioService({
    required AppConfig config,
    required String Function() getDeviceId,
    Dio? dio,
    List<Interceptor> additionalInterceptors = const [],
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: config.normalizedApiBaseUrl,
               connectTimeout: config.connectTimeout,
               receiveTimeout: config.receiveTimeout,
               sendTimeout: config.sendTimeout,
               responseType: ResponseType.json,
             ),
           ) {
    _dio.interceptors.add(DeviceIdInterceptor(getDeviceId));
    _dio.interceptors.addAll(additionalInterceptors);
  }

  final Dio _dio;

  Dio get client => _dio;
}
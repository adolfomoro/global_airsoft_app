import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import '../config/app_config.dart';
import 'interceptors/abp_error_translation_interceptor.dart';
import 'interceptors/device_id_interceptor.dart';

class DioService {
  static Dio createConfiguredDio(
    AppConfig config, {
    bool useApiPrefix = true,
    bool addNetworkLogs = true,
  }) {
    final baseUrl = useApiPrefix
        ? '${config.normalizedApiBaseUrl}${config.apiPrefix}'
        : config.normalizedApiBaseUrl;

    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        connectTimeout: config.connectTimeout,
        receiveTimeout: config.receiveTimeout,
        sendTimeout: config.sendTimeout,
        responseType: ResponseType.json,
      ),
    );

    _configureNonProductionTlsBypass(dio, config);

    if (addNetworkLogs && config.enableNetworkLogs && !config.isProduction) {
      dio.interceptors.add(
        LogInterceptor(requestBody: false, responseBody: false),
      );
    }

    dio.interceptors.add(AbpErrorTranslationInterceptor());

    return dio;
  }

  static void _configureNonProductionTlsBypass(Dio dio, AppConfig config) {
    if (config.isProduction) {
      return;
    }

    final adapter = dio.httpClientAdapter;
    if (adapter is! IOHttpClientAdapter) {
      return;
    }

    adapter.createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback = (cert, host, port) => true;
      return client;
    };
  }

  DioService({
    required AppConfig config,
    required String Function() getDeviceId,
    required Future<bool> Function() ensureDeviceSynced,
    Set<String> skipDeviceSyncPaths = const <String>{},
    Dio? dio,
    List<Interceptor> additionalInterceptors = const [],
  }) : _dio =
           dio ??
           createConfiguredDio(
             config,
             useApiPrefix: false,
             addNetworkLogs: false,
           ) {
    _dio.options.baseUrl = '${config.normalizedApiBaseUrl}${config.apiPrefix}';
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
        LogInterceptor(requestBody: false, responseBody: false),
      );
    }
  }

  final Dio _dio;

  Dio get client => _dio;
}

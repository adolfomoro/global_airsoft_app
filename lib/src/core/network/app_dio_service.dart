import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:global_airsoft_app/src/core/config/app_config.dart';
import 'package:global_airsoft_app/src/core/logging/app_logger.dart';
import 'package:global_airsoft_app/src/core/network/api_exception.dart';
import 'package:global_airsoft_app/src/core/network/interceptors/api_exception_interceptor.dart';
import 'package:global_airsoft_app/src/core/network/interceptors/device_sync_interceptor.dart';
import 'package:global_airsoft_app/src/core/network/interceptors/language_sync_interceptor.dart';

final class AppDioService {
  AppDioService._({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Dio get client => _dio;

  static AppDioService create({
    required AppConfig config,
    required AppLogger logger,
    String? Function()? getDeviceId,
    Future<bool> Function()? ensureDeviceSynced,
    required String Function() getDeviceLanguage,
    required Future<void> Function(String? contentLanguage) onContentLanguage,
    Set<String> deviceSyncSkipPaths = const <String>{},
  }) {
    final String versionedBaseUrl = _buildVersionedBaseUrl(config);
    final BaseOptions options = BaseOptions(
      baseUrl: versionedBaseUrl,
      connectTimeout: Duration(milliseconds: config.connectTimeoutMs),
      receiveTimeout: Duration(milliseconds: config.receiveTimeoutMs),
      sendTimeout: Duration(milliseconds: config.sendTimeoutMs),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
      headers: <String, Object>{Headers.acceptHeader: Headers.jsonContentType},
    );

    final Dio dio = Dio(options);

    dio.interceptors.add(
      LanguageSyncInterceptor(
        getDeviceLanguage: getDeviceLanguage,
        onContentLanguage: onContentLanguage,
      ),
    );

    if (getDeviceId != null && ensureDeviceSynced != null) {
      dio.interceptors.add(
        DeviceSyncInterceptor(
          getDeviceId: getDeviceId,
          ensureDeviceSynced: ensureDeviceSynced,
          skipPaths: deviceSyncSkipPaths,
        ),
      );
    }

    dio.interceptors.add(ApiExceptionInterceptor());

    if (config.enableDebugLogs) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: false,
          responseBody: false,
          requestHeader: false,
          responseHeader: false,
          error: true,
          logPrint: (Object object) {
            logger.info(object.toString());
          },
        ),
      );
    }

    _configureDevTls(dio: dio, config: config, logger: logger);

    return AppDioService._(dio: dio);
  }

  static void _configureDevTls({
    required Dio dio,
    required AppConfig config,
    required AppLogger logger,
  }) {
    if (config.environment != AppEnvironment.dev) {
      return;
    }

    final HttpClientAdapter adapter = dio.httpClientAdapter;
    if (adapter is! IOHttpClientAdapter) {
      return;
    }

    adapter.createHttpClient = () {
      final HttpClient client = HttpClient();
      client.badCertificateCallback = (
        X509Certificate cert,
        String host,
        int port,
      ) {
        logger.info(
          'TLS certificate validation disabled for DEV environment: $host:$port',
        );
        return true;
      };
      return client;
    };
  }

  static String _buildVersionedBaseUrl(AppConfig config) {
    final String normalizedBaseUrl = config.apiBaseUrl
        .trim()
        .replaceFirst(RegExp(r'/+$'), '');
    final String normalizedVersion = config.apiVersion
        .trim()
        .replaceAll(RegExp(r'^/+|/+$'), '');

    if (normalizedVersion.isEmpty) {
      return normalizedBaseUrl;
    }

    return '$normalizedBaseUrl/$normalizedVersion';
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) {
    return _unwrapException(
      _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      ),
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _unwrapException(
      _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      ),
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _unwrapException(
      _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      ),
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _unwrapException(
      _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
    );
  }

  static Future<Response<T>> _unwrapException<T>(
    Future<Response<T>> future,
  ) async {
    try {
      return await future;
    } on DioException catch (err) {
      if (err.error is ApiException) {
        throw err.error as ApiException;
      }
      rethrow;
    }
  }
}

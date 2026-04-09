import 'package:dio/dio.dart';
import 'package:global_airsoft_app/src/core/config/app_config.dart';
import 'package:global_airsoft_app/src/core/logging/app_logger.dart';
import 'package:global_airsoft_app/src/core/network/interceptors/api_exception_interceptor.dart';
import 'package:global_airsoft_app/src/core/network/interceptors/language_sync_interceptor.dart';

final class AppDioService {
  AppDioService._({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Dio get client => _dio;

  static AppDioService create({
    required AppConfig config,
    required AppLogger logger,
    required String Function() getDeviceLanguage,
    required Future<void> Function(String? contentLanguage) onContentLanguage,
  }) {
    final BaseOptions options = BaseOptions(
      baseUrl: config.apiBaseUrl,
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

    return AppDioService._(dio: dio);
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
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
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
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
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }
}

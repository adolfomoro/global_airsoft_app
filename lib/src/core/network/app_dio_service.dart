import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:global_airsoft_app/src/core/config/app_config.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localization_service.dart';
import 'package:global_airsoft_app/src/core/logging/app_logger.dart';
import 'package:global_airsoft_app/src/core/network/api_exception.dart';
import 'package:global_airsoft_app/src/core/network/app_http_client_factory.dart';
import 'package:global_airsoft_app/src/core/network/constants/app_network_headers.dart';
import 'package:global_airsoft_app/src/core/network/interceptors/api_exception_interceptor.dart';
import 'package:global_airsoft_app/src/core/network/interceptors/auth_security_interceptor.dart';
import 'package:global_airsoft_app/src/core/network/interceptors/device_sync_interceptor.dart';
import 'package:global_airsoft_app/src/core/network/interceptors/language_sync_interceptor.dart';

final class AppDioService {
  AppDioService._({required Dio dio}) : _dio = dio;

  static final RegExp _trailingSlashes = RegExp(r'/+$');
  static final RegExp _edgeSlashes = RegExp(r'^/+|/+$');

  final Dio _dio;

  Dio get client => _dio;

  static AppDioService create({
    required AppConfig config,
    required AppLogger logger,
    String? Function()? getDeviceId,
    Future<bool> Function()? ensureDeviceSynced,
    required String Function() getDeviceLanguage,
    required Future<void> Function(String? contentLanguage) onContentLanguage,
    required Future<ApiExceptionLocalizedMessages> Function()
    apiExceptionMessagesResolver,
    required Future<String> Function() deviceSyncRequiredMessageResolver,
    Set<String> deviceSyncSkipPaths = const <String>{},
    bool enableAuthSecurityInterceptor = false,
  }) {
    final String versionedBaseUrl = _buildVersionedBaseUrl(config);
    final BaseOptions options = BaseOptions(
      baseUrl: versionedBaseUrl,
      connectTimeout: Duration(milliseconds: config.connectTimeoutMs),
      receiveTimeout: Duration(milliseconds: config.receiveTimeoutMs),
      sendTimeout: Duration(milliseconds: config.sendTimeoutMs),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
      headers: <String, Object>{
        Headers.acceptHeader: Headers.jsonContentType,
        AppNetworkHeaders.userAgentHeader: AppNetworkHeaders.userAgentValue,
      },
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
          deviceSyncRequiredMessageResolver: deviceSyncRequiredMessageResolver,
          skipPaths: deviceSyncSkipPaths,
        ),
      );
    }

    if (enableAuthSecurityInterceptor) {
      dio.interceptors.add(AuthSecurityInterceptor(dio: dio));
    }

    dio.interceptors.add(
      ApiExceptionInterceptor(
        logger: logger,
        localizedMessagesResolver: apiExceptionMessagesResolver,
      ),
    );

    if (config.enableDebugLogs) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: false,
          responseBody: false,
          requestHeader: false,
          responseHeader: false,
          error: true,
          logPrint: (Object object) {
            logger.debug(object.toString());
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
      return AppHttpClientFactory.create(
        allowBadCertificates: true,
        onBadCertificateAccepted: (String host, int port) {
          logger.debug(
            'TLS certificate validation disabled for DEV environment: $host:$port',
          );
        },
      );
    };
  }

  static String _buildVersionedBaseUrl(AppConfig config) {
    final String normalizedBaseUrl = config.apiBaseUrl.trim().replaceFirst(
      _trailingSlashes,
      '',
    );
    final String normalizedVersion = config.apiVersion.trim().replaceAll(
      _edgeSlashes,
      '',
    );

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
      final Object? error = err.error;
      if (error is ApiException) {
        throw error as Object;
      }
      rethrow;
    }
  }
}

Future<ApiExceptionLocalizedMessages> buildLocalizedApiExceptionMessages(
  AppLocalizationService localizationService,
) async {
  final List<String> localizedValues =
      await Future.wait<String>(<Future<String>>[
        localizationService.tr(AppLocaleKeys.commonGenericApiErrorMessage),
        localizationService.tr(AppLocaleKeys.commonValidationError),
      ]);

  final String genericMessage = localizedValues[0];

  return ApiExceptionLocalizedMessages(
    badResponseFallbackMessage: genericMessage,
    connectionTimeoutMessage: genericMessage,
    sendTimeoutMessage: genericMessage,
    receiveTimeoutMessage: genericMessage,
    badCertificateMessage: genericMessage,
    requestCancelledMessage: genericMessage,
    connectionErrorMessage: genericMessage,
    unknownErrorMessage: genericMessage,
    validationErrorMessage: localizedValues[1],
  );
}

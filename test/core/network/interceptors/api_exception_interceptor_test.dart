import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_airsoft_app/src/core/config/app_config.dart';
import 'package:global_airsoft_app/src/core/localization/app_localization_service.dart';
import 'package:global_airsoft_app/src/core/logging/app_logger.dart';
import 'package:global_airsoft_app/src/core/network/api_exception.dart';
import 'package:global_airsoft_app/src/core/network/app_dio_service.dart';

final class _StaticHttpClientAdapter implements HttpClientAdapter {
  _StaticHttpClientAdapter({required this.responseBody});

  final ResponseBody responseBody;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await requestStream?.drain<void>();
    return responseBody;
  }

  @override
  void close({bool force = false}) {}
}

AppConfig _buildTestConfig() {
  return AppConfig(
    environment: AppEnvironment.test,
    enableDebugLogs: false,
    apiBaseUrl: 'https://api.example.com',
    apiVersion: '',
    connectTimeoutMs: 5000,
    receiveTimeoutMs: 5000,
    sendTimeoutMs: 5000,
    datadogEnabled: false,
    datadogClientToken: '',
    datadogRumApplicationId: '',
    datadogServiceName: 'global_airsoft_app',
    datadogSite: 'us1',
    googleSignInServerClientId: '',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    AppLogger.instance.setRemoteErrorReporter(null);
  });

  test('logs correlation id for unexpected backend failures', () async {
    final List<Map<String, Object?>> loggedAttributes =
        <Map<String, Object?>>[];
    final List<String> loggedMessages = <String>[];

    AppLogger.instance.setRemoteErrorReporter((
      String message, {
      Object? error,
      StackTrace? stackTrace,
      Map<String, Object?> attributes = const <String, Object?>{},
    }) {
      loggedMessages.add(message);
      loggedAttributes.add(attributes);
    });

    final AppLocalizationService localizationService = AppLocalizationService(
      locale: const Locale('en'),
    );
    final AppDioService service = AppDioService.create(
      config: _buildTestConfig(),
      logger: AppLogger.instance,
      getDeviceLanguage: () => 'en',
      onContentLanguage: (_) async {},
      apiExceptionMessagesResolver: () {
        return buildLocalizedApiExceptionMessages(localizationService);
      },
      deviceSyncRequiredMessageResolver: () async {
        return 'An error occurred. Please try again later.';
      },
    );

    service.client.httpClientAdapter = _StaticHttpClientAdapter(
      responseBody: ResponseBody.fromString(
        '{"error":{"code":"GlobalAirsoft:ServerError"}}',
        HttpStatus.internalServerError,
        headers: <String, List<String>>{
          Headers.contentTypeHeader: <String>[Headers.jsonContentType],
          'AbpErrorFormat': <String>['true'],
          'X-Correlation-Id': <String>['corr-log-123'],
        },
      ),
    );

    await expectLater(
      service.get<dynamic>('/failure'),
      throwsA(
        isA<ServerApiException>()
            .having(
              (ServerApiException error) => error.correlationId,
              'correlationId',
              'corr-log-123',
            )
            .having(
              (ServerApiException error) => error.isUnexpectedFailure,
              'isUnexpectedFailure',
              isTrue,
            ),
      ),
    );

    expect(loggedMessages, <String>[
      'Unexpected API failure returned by backend.',
    ]);
    expect(loggedAttributes.single['correlation_id'], 'corr-log-123');
    expect(
      loggedAttributes.single['http_status_code'],
      HttpStatus.internalServerError,
    );
    expect(loggedAttributes.single['http_path'], '/failure');
    expect(loggedAttributes.single['api_exception_type'], 'ServerApiException');
  });
}

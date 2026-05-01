import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Locale;

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_airsoft_app/src/core/config/app_config.dart';
import 'package:global_airsoft_app/src/core/localization/app_localization_service.dart';
import 'package:global_airsoft_app/src/core/logging/app_logger.dart';
import 'package:global_airsoft_app/src/core/network/app_dio_service.dart';
import 'package:global_airsoft_app/src/core/network/constants/app_network_headers.dart';

final class _RecordingHttpClientAdapter implements HttpClientAdapter {
  RequestOptions? lastRequestOptions;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequestOptions = options;
    await requestStream?.drain<void>();

    return ResponseBody.fromString(
      '{"ok":true}',
      HttpStatus.ok,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
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

  test('adds the hardcoded user agent to outgoing requests', () async {
    final AppLocalizationService localizationService = AppLocalizationService(
      locale: const Locale('en'),
    );
    final _RecordingHttpClientAdapter adapter = _RecordingHttpClientAdapter();

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

    service.client.httpClientAdapter = adapter;

    await service.get<dynamic>('/health');

    expect(
      adapter.lastRequestOptions?.headers[AppNetworkHeaders.userAgentHeader],
      AppNetworkHeaders.userAgentValue,
    );
  });
}

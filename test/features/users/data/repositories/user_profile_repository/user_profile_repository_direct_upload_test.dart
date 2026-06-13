import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Locale;

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_airsoft_app/src/core/config/app_config.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localization_service.dart';
import 'package:global_airsoft_app/src/core/logging/app_logger.dart';
import 'package:global_airsoft_app/src/core/network/app_dio_service.dart';
import 'package:global_airsoft_app/src/features/files/domain/models/direct_file_upload_authorization.dart';
import 'package:global_airsoft_app/src/features/files/domain/models/direct_file_upload_source.dart';
import 'package:global_airsoft_app/src/features/users/data/constants/user_profile_api_paths.dart';
import 'package:global_airsoft_app/src/features/users/data/exceptions/user_profile_exception.dart';
import 'package:global_airsoft_app/src/features/users/data/repositories/user_profile_repository/user_profile_repository.dart';

final class _RecordingHttpClientAdapter implements HttpClientAdapter {
  _RecordingHttpClientAdapter({required this.respond});

  final Future<ResponseBody> Function(RequestOptions options) respond;
  RequestOptions? lastRequestOptions;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequestOptions = options;
    await requestStream?.drain<void>();
    return respond(options);
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

Future<UserProfileRepository> _buildRepository(
  _RecordingHttpClientAdapter adapter,
) async {
  final AppLocalizationService localizationService = AppLocalizationService(
    locale: const Locale('en'),
  );
  final AppDioService dioService = AppDioService.create(
    config: _buildTestConfig(),
    logger: AppLogger.instance,
    getDeviceLanguage: () => 'en',
    onContentLanguage: (_) async {},
    apiExceptionMessagesResolver: () {
      return buildLocalizedApiExceptionMessages(localizationService);
    },
    deviceSyncRequiredMessageResolver: () async {
      return localizationService.tr(AppLocaleKeys.commonGenericApiErrorMessage);
    },
  );
  dioService.client.httpClientAdapter = adapter;

  return UserProfileRepository(
    dioService: dioService,
    localizationService: localizationService,
  );
}

DirectFileUploadSource _source() {
  return DirectFileUploadSource(
    fileName: 'profile.jpg',
    contentType: 'image/jpeg',
    sizeBytes: 1234,
    openRead: () => Stream<List<int>>.empty(),
  );
}

ResponseBody _authorizationBody() {
  return ResponseBody.fromString(
    '{"uploadSessionId":"session-1","fileId":"file-1","uploadUrl":"https://storage.example.com/profile.jpg","method":"PUT","requiredHeaders":{"Content-Type":"image/jpeg","x-amz-meta-checksum":"abc"},"expiresAtUtc":"2026-06-13T12:00:00Z","maxFileSizeBytes":1048576}',
    HttpStatus.ok,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>[Headers.jsonContentType],
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'initiate profile picture upload posts metadata and parses authorization',
    () async {
      final _RecordingHttpClientAdapter adapter = _RecordingHttpClientAdapter(
        respond: (RequestOptions options) async {
          expect(
            options.path,
            UserProfileApiPaths.currentUserProfilePictureUploadUrl,
          );
          return _authorizationBody();
        },
      );
      final UserProfileRepository repository = await _buildRepository(adapter);

      final DirectFileUploadAuthorization authorization = await repository
          .initiateCurrentUserProfilePictureUpload(
            _source(),
            expectedChecksum: 'abc',
            checksumAlgorithm: 'sha256',
            idempotencyKey: 'profile-upload',
          );

      final RequestOptions requestOptions = adapter.lastRequestOptions!;
      expect(requestOptions.method, 'POST');
      expect(
        requestOptions.path,
        UserProfileApiPaths.currentUserProfilePictureUploadUrl,
      );
      expect(requestOptions.data, <String, dynamic>{
        'fileName': 'profile.jpg',
        'contentType': 'image/jpeg',
        'sizeBytes': 1234,
        'expectedChecksum': 'abc',
        'checksumAlgorithm': 'sha256',
        'idempotencyKey': 'profile-upload',
      });
      expect(authorization.uploadSessionId, 'session-1');
      expect(authorization.fileId, 'file-1');
      expect(authorization.uploadUrl.host, 'storage.example.com');
      expect(authorization.requiredHeaders['Content-Type'], 'image/jpeg');
    },
  );

  test(
    'initiate profile picture upload maps invalid payload to profile exception',
    () async {
      final _RecordingHttpClientAdapter adapter = _RecordingHttpClientAdapter(
        respond: (RequestOptions options) async {
          expect(
            options.path,
            UserProfileApiPaths.currentUserProfilePictureUploadUrl,
          );
          return ResponseBody.fromString(
            '{"uploadUrl":""}',
            HttpStatus.ok,
            headers: <String, List<String>>{
              Headers.contentTypeHeader: <String>[Headers.jsonContentType],
            },
          );
        },
      );
      final UserProfileRepository repository = await _buildRepository(adapter);

      await expectLater(
        repository.initiateCurrentUserProfilePictureUpload(_source()),
        throwsA(isA<UserProfileException>()),
      );
    },
  );
}

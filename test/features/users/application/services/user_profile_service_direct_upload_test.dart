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
import 'package:global_airsoft_app/src/features/files/application/services/direct_file_upload_service.dart';
import 'package:global_airsoft_app/src/features/files/application/services/file_content_type_resolver.dart';
import 'package:global_airsoft_app/src/features/files/data/repositories/direct_file_upload_repository.dart';
import 'package:global_airsoft_app/src/features/users/application/services/user_profile_service.dart';
import 'package:global_airsoft_app/src/features/users/data/constants/user_profile_api_paths.dart';
import 'package:global_airsoft_app/src/features/users/data/repositories/user_profile_repository/user_profile_repository.dart';

final class _RecordingHttpClientAdapter implements HttpClientAdapter {
  _RecordingHttpClientAdapter({required this.respond});

  final Future<ResponseBody> Function(RequestOptions options, List<int> body)
  respond;
  final List<RequestOptions> requestOptions = <RequestOptions>[];
  final List<List<int>> bodies = <List<int>>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final List<int> body = <int>[];
    final Stream<Uint8List> resolvedRequestStream =
        requestStream ?? const Stream<Uint8List>.empty();
    await for (final Uint8List chunk in resolvedRequestStream) {
      body.addAll(chunk);
    }

    requestOptions.add(options);
    bodies.add(body);
    return respond(options, body);
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

Future<UserProfileRepository> _buildProfileRepository(
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

ResponseBody _authorizationBody() {
  return ResponseBody.fromString(
    '{"uploadSessionId":"session-1","fileId":"file-1","uploadUrl":"https://storage.example.com/profile.jpg","method":"PUT","requiredHeaders":{"Content-Type":"image/jpeg"},"expiresAtUtc":"2099-01-01T00:00:00Z","maxFileSizeBytes":1048576}',
    HttpStatus.ok,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>[Headers.jsonContentType],
    },
  );
}

ResponseBody _statusBody({String uploadStatus = 'Uploaded'}) {
  final bool isComplete = uploadStatus == 'Uploaded';
  final bool isTerminal =
      isComplete || uploadStatus == 'Failed' || uploadStatus == 'Expired';

  return ResponseBody.fromString(
    '{"uploadSessionId":"session-1","fileId":"file-1","uploadStatus":"$uploadStatus","isComplete":$isComplete,"isTerminal":$isTerminal,"failureReason":null,"confirmedAtUtc":"2099-01-01T00:00:01Z","expiresAtUtc":"2099-01-01T00:00:00Z"}',
    HttpStatus.ok,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>[Headers.jsonContentType],
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'uploadCurrentUserProfilePicture initiates and uploads directly',
    () async {
      final Directory directory = Directory.systemTemp.createTempSync(
        'global_airsoft_profile_upload_test_',
      );
      addTearDown(() {
        if (directory.existsSync()) {
          directory.deleteSync(recursive: true);
        }
      });

      final File file = File('${directory.path}/profile.jpg');
      file.writeAsBytesSync(<int>[0xFF, 0xD8, 0xFF, 0x00]);

      final _RecordingHttpClientAdapter apiAdapter =
          _RecordingHttpClientAdapter(
            respond: (RequestOptions options, List<int> body) async {
              return switch (options.path) {
                UserProfileApiPaths.currentUserProfilePictureUploadUrl =>
                  _authorizationBody(),
                '/users/me/profile-picture/uploads/session-1/complete' =>
                  _statusBody(),
                _ => throw StateError('Unexpected path: ${options.path}'),
              };
            },
          );
      final _RecordingHttpClientAdapter storageAdapter =
          _RecordingHttpClientAdapter(
            respond: (RequestOptions options, List<int> body) async {
              expect(options.method, 'PUT');
              expect(
                options.uri.toString(),
                'https://storage.example.com/profile.jpg',
              );
              expect(body, <int>[0xFF, 0xD8, 0xFF, 0x00]);
              return ResponseBody.fromString('', HttpStatus.ok);
            },
          );
      final Dio storageDio = Dio();
      storageDio.httpClientAdapter = storageAdapter;

      final UserProfileService service = UserProfileService(
        repository: await _buildProfileRepository(apiAdapter),
        directFileUploadService: DirectFileUploadService(
          repository: DirectFileUploadRepository(storageClient: storageDio),
        ),
        fileContentTypeResolver: const FileContentTypeResolver(),
        profilePictureUploadStatusPollDelay: Duration.zero,
      );

      await service.uploadCurrentUserProfilePicture(file);

      expect(apiAdapter.requestOptions, hasLength(2));
      expect(apiAdapter.requestOptions[0].method, 'POST');
      expect(apiAdapter.requestOptions[0].data, <String, dynamic>{
        'fileName': 'profile.jpg',
        'contentType': 'image/jpeg',
        'sizeBytes': 4,
      });
      expect(apiAdapter.requestOptions[1].method, 'POST');
      expect(
        apiAdapter.requestOptions[1].path,
        UserProfileApiPaths.currentUserProfilePictureUploadComplete(
          'session-1',
        ),
      );
      expect(
        storageAdapter.requestOptions.single.headers['Content-Type'],
        'image/jpeg',
      );
    },
  );
}

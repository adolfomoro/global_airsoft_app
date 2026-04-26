import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_airsoft_app/src/core/config/app_config.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localization_service.dart';
import 'package:global_airsoft_app/src/core/logging/app_logger.dart';
import 'package:global_airsoft_app/src/core/network/app_dio_service.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/auth_repository.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/dto/check_username_availability_input_dto.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/dto/check_username_availability_output_dto.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/dto/create_user_output_dto.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/dto/external_sign_up_confirm_input_dto.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/dto/google_sign_up_confirm_input_dto.dart';

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

ResponseBody _successBody() {
  return ResponseBody.fromString(
    '{"profile":{"id":"user-1","username":"player1"},"tokens":{"jwtToken":"jwt-token","refreshToken":"refresh-token"}}',
    HttpStatus.ok,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>[Headers.jsonContentType],
    },
  );
}

Future<AuthRepository> _buildRepository(
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
    badResponseFallbackMessageResolver: () async {
      return localizationService.tr(AppLocaleKeys.commonGenericApiErrorMessage);
    },
  );
  dioService.client.httpClientAdapter = adapter;

  return AuthRepository(
    dioService: dioService,
    localizationService: localizationService,
  );
}

Map<String, String> _fieldsAsMap(FormData formData) {
  return <String, String>{
    for (final MapEntry<String, String> entry in formData.fields)
      entry.key: entry.value,
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('signUpWithGoogle sends multipart without profile picture', () async {
    final _RecordingHttpClientAdapter adapter = _RecordingHttpClientAdapter(
      respond: (RequestOptions options) async => _successBody(),
    );
    final AuthRepository repository = await _buildRepository(adapter);

    final CreateUserOutputDto output = await repository.signUpWithGoogle(
      GoogleSignUpConfirmInputDto(
        challengeToken: 'challenge-123',
        username: 'player-one',
      ),
    );

    final RequestOptions requestOptions = adapter.lastRequestOptions!;
    expect(requestOptions.data, isA<FormData>());

    final FormData formData = requestOptions.data as FormData;
    expect(_fieldsAsMap(formData), <String, String>{
      ExternalSignUpConfirmInputDto.challengeTokenField: 'challenge-123',
      ExternalSignUpConfirmInputDto.usernameField: 'player-one',
    });
    expect(formData.files, isEmpty);
    expect(output.profile.username, 'player1');
  });

  test('signUpWithGoogle sends multipart with profile picture file', () async {
    final _RecordingHttpClientAdapter adapter = _RecordingHttpClientAdapter(
      respond: (RequestOptions options) async => _successBody(),
    );
    final AuthRepository repository = await _buildRepository(adapter);

    final CreateUserOutputDto output = await repository.signUpWithGoogle(
      GoogleSignUpConfirmInputDto(
        challengeToken: 'challenge-456',
        username: 'player-two',
        profilePictureFile: MultipartFile.fromBytes(<int>[
          1,
          2,
          3,
          4,
        ], filename: 'photo.jpg'),
      ),
    );

    final RequestOptions requestOptions = adapter.lastRequestOptions!;
    expect(requestOptions.data, isA<FormData>());

    final FormData formData = requestOptions.data as FormData;
    expect(_fieldsAsMap(formData), <String, String>{
      ExternalSignUpConfirmInputDto.challengeTokenField: 'challenge-456',
      ExternalSignUpConfirmInputDto.usernameField: 'player-two',
    });
    expect(formData.files, hasLength(1));
    expect(
      formData.files.single.key,
      ExternalSignUpConfirmInputDto.profilePictureFileField,
    );
    expect(formData.files.single.value.filename, 'photo.jpg');
    expect(output.tokens.jwtToken, 'jwt-token');
  });

  test('checkUsernameAvailability sends query and parses suggestions', () async {
    final _RecordingHttpClientAdapter adapter = _RecordingHttpClientAdapter(
      respond: (RequestOptions options) async {
        return ResponseBody.fromString(
          '{"userName":"player","isAvailable":false,"suggestions":["player.1","player.2"]}',
          HttpStatus.ok,
          headers: <String, List<String>>{
            Headers.contentTypeHeader: <String>[Headers.jsonContentType],
          },
        );
      },
    );
    final AuthRepository repository = await _buildRepository(adapter);

    final CheckUsernameAvailabilityOutputDto output = await repository
        .checkUsernameAvailability(
          const CheckUsernameAvailabilityInputDto(userName: 'player'),
        );

    final RequestOptions requestOptions = adapter.lastRequestOptions!;
    expect(requestOptions.path, '/auth/usernames/availability');
    expect(requestOptions.queryParameters, <String, dynamic>{
      CheckUsernameAvailabilityInputDto.userNameField: 'player',
    });
    expect(output.isAvailable, isFalse);
    expect(output.suggestions, <String>['player.1', 'player.2']);
  });
}

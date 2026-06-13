import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_airsoft_app/src/features/files/data/dto/direct_file_upload_authorization_dto.dart';
import 'package:global_airsoft_app/src/features/files/data/exceptions/direct_file_upload_exception.dart';
import 'package:global_airsoft_app/src/features/files/data/repositories/direct_file_upload_repository.dart';
import 'package:global_airsoft_app/src/features/files/domain/models/direct_file_upload_authorization.dart';
import 'package:global_airsoft_app/src/features/files/domain/models/direct_file_upload_source.dart';

final class _RecordingHttpClientAdapter implements HttpClientAdapter {
  _RecordingHttpClientAdapter({required this.respond});

  final Future<ResponseBody> Function(
    RequestOptions options,
    List<int> body,
  )
  respond;
  RequestOptions? lastRequestOptions;
  List<int> lastBody = const <int>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequestOptions = options;
    final List<int> body = <int>[];
    final Stream<Uint8List> resolvedRequestStream =
        requestStream ?? const Stream<Uint8List>.empty();
    await for (final Uint8List chunk in resolvedRequestStream) {
      body.addAll(chunk);
    }
    lastBody = body;
    return respond(options, body);
  }

  @override
  void close({bool force = false}) {}
}

DirectFileUploadAuthorization _authorization({
  String method = 'PUT',
  int maxFileSizeBytes = 1024,
  DateTime? expiresAtUtc,
}) {
  return DirectFileUploadAuthorization(
    uploadSessionId: 'session-1',
    fileId: 'file-1',
    uploadUrl: Uri.parse('https://storage.example.com/files/photo.jpg?token=1'),
    method: method,
    requiredHeaders: const <String, String>{
      Headers.contentTypeHeader: 'image/jpeg',
      'x-amz-meta-checksum': 'abc',
    },
    expiresAtUtc:
        expiresAtUtc ?? DateTime.now().toUtc().add(const Duration(minutes: 10)),
    maxFileSizeBytes: maxFileSizeBytes,
  );
}

DirectFileUploadSource _source({
  String fileName = 'photo.jpg',
  String contentType = 'image/jpeg',
  int sizeBytes = 4,
}) {
  return DirectFileUploadSource(
    fileName: fileName,
    contentType: contentType,
    sizeBytes: sizeBytes,
    openRead: () => Stream<List<int>>.fromIterable(<List<int>>[
      <int>[1, 2],
      <int>[3, 4],
    ]),
  );
}

void main() {
  test('upload sends PUT to absolute storage URL with required headers', () async {
    final _RecordingHttpClientAdapter adapter = _RecordingHttpClientAdapter(
      respond: (RequestOptions options, List<int> body) async {
        expect(options.method, 'PUT');
        expect(body, <int>[1, 2, 3, 4]);
        return ResponseBody.fromString('', HttpStatus.ok);
      },
    );
    final Dio dio = Dio();
    dio.httpClientAdapter = adapter;
    final DirectFileUploadRepository repository = DirectFileUploadRepository(
      storageClient: dio,
    );

    await repository.upload(
      authorization: _authorization(),
      source: _source(),
    );

    final RequestOptions requestOptions = adapter.lastRequestOptions!;
    expect(requestOptions.method, 'PUT');
    expect(
      requestOptions.uri.toString(),
      'https://storage.example.com/files/photo.jpg?token=1',
    );
    expect(requestOptions.headers[Headers.contentTypeHeader], 'image/jpeg');
    expect(requestOptions.headers[Headers.contentLengthHeader], 4);
    expect(requestOptions.headers['x-amz-meta-checksum'], 'abc');
    expect(adapter.lastBody, <int>[1, 2, 3, 4]);
  });

  test('upload rejects unsupported authorization method', () async {
    final DirectFileUploadRepository repository = DirectFileUploadRepository(
      storageClient: Dio(),
    );

    await expectLater(
      repository.upload(
        authorization: _authorization(method: 'POST'),
        source: _source(),
      ),
      throwsA(isA<DirectFileUploadException>()),
    );
  });

  test('upload rejects source larger than authorized size', () async {
    final DirectFileUploadRepository repository = DirectFileUploadRepository(
      storageClient: Dio(),
    );

    await expectLater(
      repository.upload(
        authorization: _authorization(maxFileSizeBytes: 3),
        source: _source(),
      ),
      throwsA(isA<DirectFileUploadException>()),
    );
  });

  test('upload rejects content type different from required header', () async {
    final DirectFileUploadRepository repository = DirectFileUploadRepository(
      storageClient: Dio(),
    );

    await expectLater(
      repository.upload(
        authorization: _authorization(),
        source: _source(contentType: 'image/png'),
      ),
      throwsA(isA<DirectFileUploadException>()),
    );
  });

  test('upload throws when storage returns non success status code', () async {
    final _RecordingHttpClientAdapter adapter = _RecordingHttpClientAdapter(
      respond: (RequestOptions options, List<int> body) async {
        expect(options.method, 'PUT');
        expect(body, <int>[1, 2, 3, 4]);
        return ResponseBody.fromString('', HttpStatus.forbidden);
      },
    );
    final Dio dio = Dio();
    dio.httpClientAdapter = adapter;
    final DirectFileUploadRepository repository = DirectFileUploadRepository(
      storageClient: dio,
    );

    await expectLater(
      repository.upload(
        authorization: _authorization(),
        source: _source(),
      ),
      throwsA(
        isA<DirectFileUploadException>().having(
          (DirectFileUploadException error) => error.statusCode,
          'statusCode',
          HttpStatus.forbidden,
        ),
      ),
    );
  });

  test('authorization dto parses backend payload into domain model', () {
    final DirectFileUploadAuthorization authorization =
        DirectFileUploadAuthorizationDto.fromJson(<String, dynamic>{
          'uploadSessionId': 'session-1',
          'fileId': 'file-1',
          'uploadUrl': 'https://storage.example.com/file.jpg',
          'method': 'put',
          'requiredHeaders': <String, dynamic>{
            Headers.contentTypeHeader: 'image/jpeg',
          },
          'expiresAtUtc': '2026-06-13T12:00:00Z',
          'maxFileSizeBytes': 1024,
        }).toDomain();

    expect(authorization.method, 'PUT');
    expect(authorization.uploadUrl.host, 'storage.example.com');
    expect(
      authorization.requiredHeaders[Headers.contentTypeHeader],
      'image/jpeg',
    );
    expect(authorization.maxFileSizeBytes, 1024);
  });

  test('authorization dto rejects invalid upload URL', () {
    final DirectFileUploadAuthorizationDto dto =
        DirectFileUploadAuthorizationDto.fromJson(<String, dynamic>{
          'uploadSessionId': 'session-1',
          'fileId': 'file-1',
          'uploadUrl': 'ftp://storage.example.com/file.jpg',
          'method': 'PUT',
          'requiredHeaders': <String, dynamic>{},
          'expiresAtUtc': '2026-06-13T12:00:00Z',
          'maxFileSizeBytes': 1024,
        });

    expect(dto.toDomain, throwsA(isA<FormatException>()));
  });
}

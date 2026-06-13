import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:global_airsoft_app/src/core/network/constants/app_network_headers.dart';
import 'package:global_airsoft_app/src/core/network/multipart_upload_util.dart';

void main() {
  test('createFromUrl downloads bytes and derives a filename', () async {
    final HttpServer server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      0,
    );
    addTearDown(() async {
      await server.close(force: true);
    });

    final List<int> expectedBytes = <int>[1, 2, 3, 4, 5, 6];
    server.listen((HttpRequest request) async {
      expect(
        request.headers.value(HttpHeaders.userAgentHeader),
        AppNetworkHeaders.userAgentValue,
      );
      request.response.statusCode = HttpStatus.ok;
      request.response.headers.contentType = ContentType('image', 'jpeg');
      request.response.add(expectedBytes);
      await request.response.close();
    });

    final file = await MultipartUploadUtil.createFromUrl(
      'http://${server.address.host}:${server.port}/profile-photo',
    );

    expect(file.filename, 'download.jpg');
    expect(file.length, expectedBytes.length);
  });

  test('createFromUrl rejects unsupported schemes', () async {
    await expectLater(
      MultipartUploadUtil.createFromUrl('ftp://example.com/photo.jpg'),
      throwsA(isA<ArgumentError>()),
    );
  });
}

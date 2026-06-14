import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:global_airsoft_app/src/features/files/application/services/file_content_type_resolver.dart';

void main() {
  test('resolveFromFileName returns supported image content types', () {
    const FileContentTypeResolver resolver = FileContentTypeResolver();

    expect(resolver.resolveFromFileName('photo.jpg'), 'image/jpeg');
    expect(resolver.resolveFromFileName('photo.PNG'), 'image/png');
    expect(resolver.resolveFromFileName('photo.webp'), 'image/webp');
    expect(
      resolver.resolveFromFileName('photo.unknown'),
      'application/octet-stream',
    );
  });

  test('resolve detects jpeg content type from file signature', () async {
    final Directory directory = Directory.systemTemp.createTempSync(
      'global_airsoft_content_type_test_',
    );
    addTearDown(() {
      if (directory.existsSync()) {
        directory.deleteSync(recursive: true);
      }
    });

    final File file = File('${directory.path}/profile');
    file.writeAsBytesSync(<int>[0xFF, 0xD8, 0xFF, 0x00]);

    const FileContentTypeResolver resolver = FileContentTypeResolver();

    expect(await resolver.resolve(file), 'image/jpeg');
  });
}

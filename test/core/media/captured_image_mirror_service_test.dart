import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:global_airsoft_app/src/core/media/captured_image_mirror_service.dart';
import 'package:image/image.dart' as image;

void main() {
  test('mirrors a captured photo horizontally when requested', () async {
    final Directory tempDirectory = await Directory.systemTemp.createTemp(
      'captured_image_mirror_service_test',
    );
    addTearDown(() => tempDirectory.deleteSync(recursive: true));

    final File sourceFile = File(
      '${tempDirectory.path}${Platform.pathSeparator}capture.jpg',
    );

    final image.Image originalImage = image.Image(width: 64, height: 32);
    for (int y = 0; y < originalImage.height; y++) {
      for (int x = 0; x < originalImage.width; x++) {
        if (x < originalImage.width ~/ 2) {
          originalImage.setPixelRgb(x, y, 255, 0, 0);
        } else {
          originalImage.setPixelRgb(x, y, 0, 0, 255);
        }
      }
    }

    await sourceFile.writeAsBytes(image.encodeJpg(originalImage, quality: 100));

    final CapturedImageMirrorService service = CapturedImageMirrorService();
    final File mirroredFile = await service.mirrorCapturedPhotoIfNeeded(
      sourceFile: sourceFile,
      shouldMirror: true,
    );

    expect(mirroredFile.path, sourceFile.path);

    final image.Image? mirroredImage = image.decodeJpg(
      await mirroredFile.readAsBytes(),
    );

    expect(mirroredImage, isNotNull);

    final image.Pixel leftPixel = mirroredImage!.getPixel(8, 16);
    final image.Pixel rightPixel = mirroredImage.getPixel(56, 16);

    expect(leftPixel.r, lessThan(leftPixel.b));
    expect(rightPixel.b, lessThan(rightPixel.r));
  });
}

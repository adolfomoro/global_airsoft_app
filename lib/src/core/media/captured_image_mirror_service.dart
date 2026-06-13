import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as image;

final class CapturedImageMirrorService {
  const CapturedImageMirrorService();

  Future<File> mirrorCapturedPhotoIfNeeded({
    required File sourceFile,
    required bool shouldMirror,
  }) async {
    if (!shouldMirror || !sourceFile.existsSync()) {
      return sourceFile;
    }

    try {
      final Uint8List bytes = await sourceFile.readAsBytes();
      final image.Image? decodedImage =
          image.decodeJpg(bytes) ?? image.decodeImage(bytes);

      if (decodedImage == null) {
        return sourceFile;
      }

      final image.Image orientedImage = image.bakeOrientation(decodedImage);
      final image.Image mirroredImage = image.flipHorizontal(orientedImage);
      final Uint8List mirroredBytes = image.encodeJpg(mirroredImage);

      await sourceFile.writeAsBytes(mirroredBytes, flush: true);
    } catch (_) {
      return sourceFile;
    }

    return sourceFile;
  }
}

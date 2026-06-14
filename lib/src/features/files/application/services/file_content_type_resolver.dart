import 'dart:io';

import 'package:path/path.dart' as path;

final class FileContentTypeResolver {
  const FileContentTypeResolver();

  static const String fallbackContentType = 'application/octet-stream';

  Future<String> resolve(File file) async {
    final String byExtension = resolveFromFileName(path.basename(file.path));
    if (byExtension != fallbackContentType) {
      return byExtension;
    }

    return _resolveFromSignature(file);
  }

  String resolveFromFileName(String fileName) {
    final String extension = path.extension(fileName).trim().toLowerCase();
    return switch (extension) {
      '.jpg' || '.jpeg' => 'image/jpeg',
      '.png' => 'image/png',
      '.webp' => 'image/webp',
      '.gif' => 'image/gif',
      '.heic' => 'image/heic',
      '.heif' => 'image/heif',
      _ => fallbackContentType,
    };
  }

  Future<String> _resolveFromSignature(File file) async {
    if (!file.existsSync()) {
      return fallbackContentType;
    }

    final RandomAccessFile openedFile = file.openSync();
    try {
      final int length = openedFile.lengthSync();
      if (length <= 0) {
        return fallbackContentType;
      }

      final int bytesToRead = length < 12 ? length : 12;
      final List<int> bytes = openedFile.readSync(bytesToRead);
      return _resolveFromBytes(bytes);
    } finally {
      openedFile.closeSync();
    }
  }

  String _resolveFromBytes(List<int> bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'image/jpeg';
    }

    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      return 'image/png';
    }

    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }

    if (bytes.length >= 6 &&
        bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38 &&
        (bytes[4] == 0x37 || bytes[4] == 0x39) &&
        bytes[5] == 0x61) {
      return 'image/gif';
    }

    return fallbackContentType;
  }
}

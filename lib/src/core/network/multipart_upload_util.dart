import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;

class MultipartUploadUtil {
  static Future<MultipartFile> createFromFile(
    File file, {
    String? filename,
  }) async {
    final String actualFilename = filename ?? path.basename(file.path);
    return await MultipartFile.fromFile(file.path, filename: actualFilename);
  }

  static Future<MultipartFile> createFromUrl(
    String url, {
    String? filename,
  }) async {
    final Uri uri =
        Uri.tryParse(url) ?? (throw ArgumentError.value(url, 'url'));

    if (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw ArgumentError.value(
        url,
        'url',
        'Only http and https URLs are supported.',
      );
    }

    final HttpClient httpClient = HttpClient();
    try {
      final HttpClientRequest request = await httpClient.getUrl(uri);
      final HttpClientResponse response = await request.close();

      if (response.statusCode < HttpStatus.ok ||
          response.statusCode >= HttpStatus.multipleChoices) {
        throw HttpException('Failed to download file from $url', uri: uri);
      }

      final BytesBuilder bytesBuilder = BytesBuilder(copy: false);
      await for (final List<int> chunk in response) {
        bytesBuilder.add(chunk);
      }

      final String actualFilename =
          filename ??
          _resolveFilename(
            uri: uri,
            mimeType: response.headers.contentType?.mimeType,
          );

      return MultipartFile.fromBytes(
        bytesBuilder.takeBytes(),
        filename: actualFilename,
      );
    } finally {
      httpClient.close(force: true);
    }
  }

  static FormData createFormData(Map<String, dynamic> fields) {
    return FormData.fromMap(_normalizeFields(fields));
  }

  static Future<FormData> createMultiFileFormData({
    required Map<String, File> files,
    Map<String, dynamic>? additionalFields,
  }) async {
    final Map<String, dynamic> formFields = <String, dynamic>{};

    for (final MapEntry<String, File> entry in files.entries) {
      final MultipartFile multipartFile = await createFromFile(entry.value);
      formFields[entry.key] = multipartFile;
    }

    if (additionalFields != null) {
      formFields.addAll(additionalFields);
    }

    return createFormData(formFields);
  }

  static Map<String, dynamic> _normalizeFields(Map<String, dynamic> fields) {
    final Map<String, dynamic> normalizedFields = <String, dynamic>{};

    fields.forEach((String key, dynamic value) {
      if (value != null) {
        normalizedFields[key] = value;
      }
    });

    return normalizedFields;
  }

  static String _resolveFilename({
    required Uri uri,
    required String? mimeType,
  }) {
    final String basename = path.basename(uri.path);
    if (basename.isNotEmpty && path.extension(basename).isNotEmpty) {
      return basename;
    }

    final String? extension = _mimeTypeToExtension(mimeType);
    return 'download${extension ?? '.bin'}';
  }

  static String? _mimeTypeToExtension(String? mimeType) {
    switch (mimeType?.toLowerCase()) {
      case 'image/jpeg':
      case 'image/jpg':
        return '.jpg';
      case 'image/png':
        return '.png';
      case 'image/gif':
        return '.gif';
      case 'image/webp':
        return '.webp';
      case 'image/bmp':
        return '.bmp';
      case 'image/heic':
        return '.heic';
      case 'image/heif':
        return '.heif';
      default:
        return null;
    }
  }

  static String? getMimeType(File file) {
    final String extension = path.extension(file.path).toLowerCase();

    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.bmp':
        return 'image/bmp';
      default:
        return null;
    }
  }
}

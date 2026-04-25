import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;

class MultipartUploadUtil {
  static Future<MultipartFile> createFromFile(
    File file, {
    String fieldName = 'file',
    String? filename,
  }) async {
    final String actualFilename = filename ?? path.basename(file.path);
    return await MultipartFile.fromFile(file.path, filename: actualFilename);
  }

  static Future<FormData> createFormData(
    File file, {
    String fieldName = 'file',
    String? filename,
    Map<String, dynamic>? additionalFields,
  }) async {
    final MultipartFile multipartFile = await createFromFile(
      file,
      fieldName: fieldName,
      filename: filename,
    );

    final Map<String, dynamic> formFields = <String, dynamic>{
      fieldName: multipartFile,
    };

    if (additionalFields != null) {
      formFields.addAll(additionalFields);
    }

    return FormData.fromMap(formFields);
  }

  static Future<FormData> createMultiFileFormData({
    required Map<String, File> files,
    Map<String, dynamic>? additionalFields,
  }) async {
    final Map<String, dynamic> formFields = <String, dynamic>{};

    for (final MapEntry<String, File> entry in files.entries) {
      final MultipartFile multipartFile = await createFromFile(
        entry.value,
        fieldName: entry.key,
      );
      formFields[entry.key] = multipartFile;
    }

    if (additionalFields != null) {
      formFields.addAll(additionalFields);
    }

    return FormData.fromMap(formFields);
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

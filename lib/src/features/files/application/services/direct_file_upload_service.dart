import 'dart:io';

import 'package:dio/dio.dart';
import 'package:global_airsoft_app/src/features/files/data/repositories/direct_file_upload_repository.dart';
import 'package:global_airsoft_app/src/features/files/domain/models/direct_file_upload_authorization.dart';
import 'package:global_airsoft_app/src/features/files/domain/models/direct_file_upload_source.dart';
import 'package:path/path.dart' as path;

final class DirectFileUploadService {
  const DirectFileUploadService({
    required DirectFileUploadRepository repository,
  }) : _repository = repository;

  final DirectFileUploadRepository _repository;

  Future<void> uploadFile({
    required DirectFileUploadAuthorization authorization,
    required File file,
    required String contentType,
    DirectFileUploadProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    final int sizeBytes = await file.length();
    final DirectFileUploadSource source = DirectFileUploadSource(
      fileName: path.basename(file.path),
      contentType: contentType,
      sizeBytes: sizeBytes,
      openRead: file.openRead,
    );

    await _repository.upload(
      authorization: authorization,
      source: source,
      onProgress: onProgress,
      cancelToken: cancelToken,
    );
  }

  Future<void> uploadSource({
    required DirectFileUploadAuthorization authorization,
    required DirectFileUploadSource source,
    DirectFileUploadProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) {
    return _repository.upload(
      authorization: authorization,
      source: source,
      onProgress: onProgress,
      cancelToken: cancelToken,
    );
  }
}

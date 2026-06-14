import 'package:dio/dio.dart';
import 'package:global_airsoft_app/src/core/network/http_status_code_extensions.dart';
import 'package:global_airsoft_app/src/features/files/data/exceptions/direct_file_upload_exception.dart';
import 'package:global_airsoft_app/src/features/files/domain/models/direct_file_upload_authorization.dart';
import 'package:global_airsoft_app/src/features/files/domain/models/direct_file_upload_source.dart';

typedef DirectFileUploadProgressCallback =
    void Function(int sentBytes, int totalBytes);

final class DirectFileUploadRepository {
  const DirectFileUploadRepository({required Dio storageClient})
    : _storageClient = storageClient;

  static const String _supportedMethod = 'PUT';

  final Dio _storageClient;

  Future<void> upload({
    required DirectFileUploadAuthorization authorization,
    required DirectFileUploadSource source,
    DirectFileUploadProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    _validateAuthorization(authorization);
    _validateSource(source, authorization: authorization);

    try {
      final Map<String, Object> headers = <String, Object>{
        ...authorization.requiredHeaders,
      };
      if (!_containsHeader(headers, Headers.contentLengthHeader)) {
        headers[Headers.contentLengthHeader] = source.sizeBytes;
      }

      final Response<dynamic> response = await _storageClient.putUri<dynamic>(
        authorization.uploadUrl,
        data: source.openRead(),
        options: Options(headers: headers, contentType: source.contentType),
        cancelToken: cancelToken,
        onSendProgress: onProgress,
      );

      if (response.statusCode.isSuccessStatusCode) {
        return;
      }

      throw DirectFileUploadException(
        message: 'Direct file upload failed.',
        statusCode: response.statusCode,
      );
    } on DirectFileUploadException {
      rethrow;
    } on DioException catch (error) {
      throw DirectFileUploadException(
        message: 'Direct file upload request failed.',
        statusCode: error.response?.statusCode,
        cause: error,
      );
    }
  }

  static void _validateAuthorization(
    DirectFileUploadAuthorization authorization,
  ) {
    if (authorization.method.trim().toUpperCase() != _supportedMethod) {
      throw DirectFileUploadException(
        message: 'Unsupported direct file upload method.',
      );
    }

    if (authorization.isExpired) {
      throw DirectFileUploadException(
        message: 'Direct file upload authorization is expired.',
      );
    }
  }

  static void _validateSource(
    DirectFileUploadSource source, {
    required DirectFileUploadAuthorization authorization,
  }) {
    if (source.fileName.trim().isEmpty) {
      throw const DirectFileUploadException(
        message: 'Direct file upload file name is required.',
      );
    }

    if (source.contentType.trim().isEmpty) {
      throw const DirectFileUploadException(
        message: 'Direct file upload content type is required.',
      );
    }

    if (source.sizeBytes <= 0) {
      throw const DirectFileUploadException(
        message: 'Direct file upload content is required.',
      );
    }

    if (source.sizeBytes > authorization.maxFileSizeBytes) {
      throw const DirectFileUploadException(
        message: 'Direct file upload exceeds the authorized size.',
      );
    }

    final String? requiredContentType = _findHeaderValue(
      authorization.requiredHeaders,
      Headers.contentTypeHeader,
    );
    if (requiredContentType != null &&
        requiredContentType.trim().toLowerCase() !=
            source.contentType.trim().toLowerCase()) {
      throw const DirectFileUploadException(
        message:
            'Direct file upload content type does not match authorization.',
      );
    }
  }

  static bool _containsHeader(Map<String, Object> headers, String headerName) {
    return _findHeaderValue(headers, headerName) != null;
  }

  static String? _findHeaderValue(
    Map<String, Object> headers,
    String headerName,
  ) {
    final String normalizedHeaderName = headerName.trim().toLowerCase();
    for (final MapEntry<String, Object> entry in headers.entries) {
      if (entry.key.trim().toLowerCase() == normalizedHeaderName) {
        return entry.value.toString();
      }
    }

    return null;
  }
}

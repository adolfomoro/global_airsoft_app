import 'package:global_airsoft_app/src/features/files/domain/models/direct_file_upload_authorization.dart';

final class DirectFileUploadAuthorizationDto {
  const DirectFileUploadAuthorizationDto({
    required this.uploadSessionId,
    required this.fileId,
    required this.uploadUrl,
    required this.method,
    required this.requiredHeaders,
    required this.expiresAtUtc,
    required this.maxFileSizeBytes,
  });

  final String uploadSessionId;
  final String fileId;
  final String uploadUrl;
  final String method;
  final Map<String, String> requiredHeaders;
  final DateTime expiresAtUtc;
  final int maxFileSizeBytes;

  factory DirectFileUploadAuthorizationDto.fromJson(
    Map<String, dynamic> json,
  ) {
    final Object? uploadSessionId = json['uploadSessionId'];
    final Object? fileId = json['fileId'];
    final Object? uploadUrl = json['uploadUrl'];
    final Object? method = json['method'];
    final Object? requiredHeaders = json['requiredHeaders'];
    final Object? expiresAtUtc = json['expiresAtUtc'];
    final Object? maxFileSizeBytes = json['maxFileSizeBytes'];

    if (uploadSessionId is! String ||
        fileId is! String ||
        uploadUrl is! String ||
        method is! String ||
        expiresAtUtc is! String ||
        maxFileSizeBytes is! num) {
      throw const FormatException('Invalid direct upload authorization payload.');
    }

    final DateTime? parsedExpiration = DateTime.tryParse(expiresAtUtc);
    if (parsedExpiration == null) {
      throw const FormatException(
        'Invalid direct upload authorization expiration.',
      );
    }

    return DirectFileUploadAuthorizationDto(
      uploadSessionId: uploadSessionId,
      fileId: fileId,
      uploadUrl: uploadUrl,
      method: method,
      requiredHeaders: _parseHeaders(requiredHeaders),
      expiresAtUtc: parsedExpiration.toUtc(),
      maxFileSizeBytes: maxFileSizeBytes.toInt(),
    );
  }

  DirectFileUploadAuthorization toDomain() {
    final Uri? parsedUploadUrl = Uri.tryParse(uploadUrl.trim());
    if (parsedUploadUrl == null ||
        parsedUploadUrl.host.isEmpty ||
        (parsedUploadUrl.scheme != 'http' &&
            parsedUploadUrl.scheme != 'https')) {
      throw const FormatException('Invalid direct upload URL.');
    }

    if (uploadSessionId.trim().isEmpty || fileId.trim().isEmpty) {
      throw const FormatException('Invalid direct upload identifiers.');
    }

    final String normalizedMethod = method.trim().toUpperCase();
    if (normalizedMethod.isEmpty) {
      throw const FormatException('Direct upload method is required.');
    }

    if (maxFileSizeBytes <= 0) {
      throw const FormatException(
        'Direct upload max file size must be positive.',
      );
    }

    return DirectFileUploadAuthorization(
      uploadSessionId: uploadSessionId.trim(),
      fileId: fileId.trim(),
      uploadUrl: parsedUploadUrl,
      method: normalizedMethod,
      requiredHeaders: Map<String, String>.unmodifiable(requiredHeaders),
      expiresAtUtc: expiresAtUtc,
      maxFileSizeBytes: maxFileSizeBytes,
    );
  }

  static Map<String, String> _parseHeaders(Object? value) {
    if (value == null) {
      return const <String, String>{};
    }

    if (value is! Map<Object?, Object?>) {
      throw const FormatException('Invalid direct upload required headers.');
    }

    final Map<String, String> headers = <String, String>{};
    for (final MapEntry<Object?, Object?> entry in value.entries) {
      final Object? rawKey = entry.key;
      final Object? rawValue = entry.value;
      if (rawKey is! String || rawValue is! String) {
        throw const FormatException('Invalid direct upload required header.');
      }

      final String key = rawKey.trim();
      if (key.isEmpty) {
        throw const FormatException('Invalid direct upload required header.');
      }

      headers[key] = rawValue;
    }

    return headers;
  }
}

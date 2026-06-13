import 'dart:io';

import 'package:dio/dio.dart';
import 'package:global_airsoft_app/src/core/logging/app_logger.dart';
import 'package:global_airsoft_app/src/core/storage/app_file_storage_service.dart';
import 'package:path/path.dart' as path;

final class UserProfileOfflinePhotoStorageService {
  UserProfileOfflinePhotoStorageService({
    required AppFileStorageService fileStorage,
    required Dio downloadClient,
    required AppLogger logger,
  }) : _fileStorage = fileStorage,
       _downloadClient = downloadClient,
       _logger = logger;

  static const String _usersDirectoryName = 'users';
  static const String _profileDirectoryName = 'profile';
  static const String _profilePhotosDirectoryName = 'photos';
  static const String _profilePhotoFilePrefix = 'profile_photo_';

  final AppFileStorageService _fileStorage;
  final Dio _downloadClient;
  final AppLogger _logger;

  Future<String?> getStoredProfilePhotoPath({required String userId}) async {
    try {
      final File? file = await _resolveLatestStoredProfilePhoto(userId: userId);
      if (file == null) {
        return null;
      }

      if (file.lengthSync() == 0) {
        await clearStoredProfilePhoto(userId: userId);
        return null;
      }

      return file.path;
    } catch (error, stackTrace) {
      _logger.error(
        'Failed to resolve stored offline profile photo.',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<String?> cacheRemoteProfilePhoto({
    required String userId,
    required String mediumPhotoUrl,
    required String largePhotoUrl,
  }) async {
    final List<String> candidateUrls = <String>[
      largePhotoUrl.trim(),
      mediumPhotoUrl.trim(),
    ].where((String url) => url.isNotEmpty).toSet().toList(growable: false);

    if (candidateUrls.isEmpty) {
      await clearStoredProfileAssets(userId: userId);
      return null;
    }

    final String? existingPath = await getStoredProfilePhotoPath(userId: userId);
    for (final String candidateUrl in candidateUrls) {
      try {
        final List<int> bytes = await _downloadProfilePhotoBytes(candidateUrl);
        final File file = await _replaceStoredProfilePhoto(
          userId: userId,
          fileExtension: _resolveFileExtensionFromUrl(candidateUrl),
          writeFile: (List<String> pathSegments) {
            return _fileStorage.writeBytes(
              bytes: bytes,
              pathSegments: pathSegments,
            );
          },
        );
        return file.path;
      } catch (error, stackTrace) {
        _logger.debug(
          'Remote profile photo cache attempt failed. Trying the next candidate if available.',
        );
        _logger.error(
          'Failed to cache remote profile photo offline.',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    return existingPath;
  }

  Future<void> clearStoredProfilePhoto({required String userId}) {
    return _fileStorage.deleteDirectory(
      pathSegments: _photoDirectoryPathSegments(userId),
    );
  }

  Future<void> clearStoredProfileAssets({required String userId}) {
    return _fileStorage.deleteDirectory(
      pathSegments: _profileDirectoryPathSegments(userId),
    );
  }

  Future<List<int>> _downloadProfilePhotoBytes(String url) async {
    final Uri uri = Uri.parse(url.trim());
    if (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw ArgumentError.value(
        url,
        'url',
        'Profile photo URL must use HTTP or HTTPS.',
      );
    }

    final Response<List<int>> response = await _downloadClient.getUri<List<int>>(
      uri,
      options: Options(
        responseType: ResponseType.bytes,
        receiveDataWhenStatusError: false,
      ),
    );
    final List<int>? bytes = response.data;
    if (response.statusCode != HttpStatus.ok ||
        bytes == null ||
        bytes.isEmpty) {
      throw StateError('Profile photo download returned no usable bytes.');
    }

    return bytes;
  }

  List<String> _profileDirectoryPathSegments(String userId) {
    return <String>[
      _usersDirectoryName,
      _normalizeUserId(userId),
      _profileDirectoryName,
    ];
  }

  List<String> _photoDirectoryPathSegments(String userId) {
    return <String>[
      ..._profileDirectoryPathSegments(userId),
      _profilePhotosDirectoryName,
    ];
  }

  Future<File?> _resolveLatestStoredProfilePhoto({required String userId}) async {
    final List<File> files = await _fileStorage.listFiles(
      pathSegments: _photoDirectoryPathSegments(userId),
    );
    final List<File> profilePhotoFiles = files
        .where((File file) {
          return path.basename(file.path).startsWith(_profilePhotoFilePrefix);
        })
        .toList(growable: false);
    if (profilePhotoFiles.isEmpty) {
      return null;
    }

    profilePhotoFiles.sort((File left, File right) {
      return right.lastModifiedSync().compareTo(left.lastModifiedSync());
    });
    return profilePhotoFiles.first;
  }

  Future<File> _replaceStoredProfilePhoto({
    required String userId,
    required String fileExtension,
    required Future<File> Function(List<String> pathSegments) writeFile,
  }) async {
    await clearStoredProfilePhoto(userId: userId);

    return writeFile(<String>[
      ..._photoDirectoryPathSegments(userId),
      _buildVersionedPhotoFilename(fileExtension),
    ]);
  }

  String _buildVersionedPhotoFilename(String fileExtension) {
    final int timestamp = DateTime.now().microsecondsSinceEpoch;
    return '$_profilePhotoFilePrefix$timestamp$fileExtension';
  }

  String _resolveFileExtensionFromUrl(String url) {
    final Uri uri = Uri.parse(url);
    return _normalizeFileExtension(path.extension(uri.path));
  }

  String _normalizeFileExtension(String extension) {
    final String normalized = extension.trim().toLowerCase();
    if (normalized.isEmpty ||
        normalized == '.' ||
        normalized.contains(RegExp(r'[^a-z0-9.]'))) {
      return '.bin';
    }

    if (!normalized.startsWith('.')) {
      return '.bin';
    }

    return normalized;
  }

  String _normalizeUserId(String userId) {
    final String normalized = userId.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'User id must not be empty.');
    }

    return normalized;
  }
}

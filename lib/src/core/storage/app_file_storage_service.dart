import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

typedef AppStorageRootDirectoryResolver = Future<Directory> Function();

final class AppFileStorageService {
  AppFileStorageService({
    AppStorageRootDirectoryResolver? rootDirectoryResolver,
  }) : _rootDirectoryResolver =
           rootDirectoryResolver ?? getApplicationSupportDirectory;

  final AppStorageRootDirectoryResolver _rootDirectoryResolver;

  Future<File?> getFileIfExists({required List<String> pathSegments}) async {
    final File file = await _resolveFile(pathSegments: pathSegments);
    if (!file.existsSync()) {
      return null;
    }

    return file;
  }

  Future<File> writeBytes({
    required List<int> bytes,
    required List<String> pathSegments,
  }) async {
    final File file = await _prepareFile(pathSegments: pathSegments);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<File> copyFile({
    required File sourceFile,
    required List<String> pathSegments,
  }) async {
    final File destinationFile = await _prepareFile(pathSegments: pathSegments);
    if (destinationFile.existsSync()) {
      await destinationFile.delete();
    }

    return sourceFile.copy(destinationFile.path);
  }

  Future<void> deleteFile({required List<String> pathSegments}) async {
    final File file = await _resolveFile(pathSegments: pathSegments);
    if (!file.existsSync()) {
      return;
    }

    await file.delete();
  }

  Future<void> deleteDirectory({required List<String> pathSegments}) async {
    final Directory directory = await _resolveDirectory(
      pathSegments: pathSegments,
    );
    if (!directory.existsSync()) {
      return;
    }

    await directory.delete(recursive: true);
  }

  Future<List<File>> listFiles({required List<String> pathSegments}) async {
    final Directory directory = await _resolveDirectory(
      pathSegments: pathSegments,
    );
    if (!directory.existsSync()) {
      return const <File>[];
    }

    return directory
        .listSync(followLinks: false)
        .whereType<File>()
        .toList(growable: false);
  }

  Future<File> _prepareFile({required List<String> pathSegments}) async {
    final File file = await _resolveFile(pathSegments: pathSegments);
    await file.parent.create(recursive: true);
    return file;
  }

  Future<File> _resolveFile({required List<String> pathSegments}) async {
    final Directory rootDirectory = await _rootDirectoryResolver();
    final String relativePath = path.joinAll(_normalizeSegments(pathSegments));
    return File(path.join(rootDirectory.path, relativePath));
  }

  Future<Directory> _resolveDirectory({
    required List<String> pathSegments,
  }) async {
    final Directory rootDirectory = await _rootDirectoryResolver();
    final String relativePath = path.joinAll(_normalizeSegments(pathSegments));
    return Directory(path.join(rootDirectory.path, relativePath));
  }

  List<String> _normalizeSegments(List<String> pathSegments) {
    if (pathSegments.isEmpty) {
      throw ArgumentError.value(
        pathSegments,
        'pathSegments',
        'Path segments must not be empty.',
      );
    }

    return pathSegments.map(_normalizeSegment).toList(growable: false);
  }

  String _normalizeSegment(String segment) {
    final String normalized = segment.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(
        segment,
        'segment',
        'Path segments must not be empty.',
      );
    }

    if (normalized == '.' ||
        normalized == '..' ||
        normalized.contains(RegExp(r'[\\/]'))) {
      throw ArgumentError.value(
        segment,
        'segment',
        'Path segments must not contain path traversal or separators.',
      );
    }

    return normalized;
  }
}

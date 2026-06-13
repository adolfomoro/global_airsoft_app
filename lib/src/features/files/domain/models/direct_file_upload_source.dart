import 'dart:async';

final class DirectFileUploadSource {
  const DirectFileUploadSource({
    required this.fileName,
    required this.contentType,
    required this.sizeBytes,
    required this.openRead,
  });

  final String fileName;
  final String contentType;
  final int sizeBytes;
  final Stream<List<int>> Function() openRead;
}

import 'dart:io';

class ProfilePhoto {
  const ProfilePhoto.network(String url) : networkUrl = url, localFile = null;

  const ProfilePhoto.local(File file) : networkUrl = null, localFile = file;

  const ProfilePhoto.empty() : networkUrl = null, localFile = null;

  final String? networkUrl;
  final File? localFile;

  bool get isNetwork => networkUrl != null && networkUrl!.isNotEmpty;
  bool get isLocal => localFile != null;
  bool get hasPhoto => isNetwork || isLocal;
  bool get isEmpty => !hasPhoto;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ProfilePhoto &&
        other.networkUrl == networkUrl &&
        other.localFile?.path == localFile?.path;
  }

  @override
  int get hashCode => networkUrl.hashCode ^ (localFile?.path.hashCode ?? 0);

  @override
  String toString() {
    if (isNetwork) return 'ProfilePhoto.network($networkUrl)';
    if (isLocal) return 'ProfilePhoto.local(${localFile!.path})';
    return 'ProfilePhoto.empty()';
  }
}

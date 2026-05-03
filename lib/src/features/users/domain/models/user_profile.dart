import 'dart:io';

import 'package:global_airsoft_app/src/core/media/profile_photo.dart';

final class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    required this.fullName,
    required this.bio,
    required this.mediumProfilePictureUrl,
    required this.largeProfilePictureUrl,
    this.localProfilePicturePath = '',
  });

  final String id;
  final String username;
  final String fullName;
  final String bio;
  final String mediumProfilePictureUrl;
  final String largeProfilePictureUrl;
  final String localProfilePicturePath;

  UserProfile copyWith({
    String? fullName,
    String? bio,
    String? mediumProfilePictureUrl,
    String? largeProfilePictureUrl,
    String? localProfilePicturePath,
  }) {
    return UserProfile(
      id: id,
      username: username,
      fullName: fullName ?? this.fullName,
      bio: bio ?? this.bio,
      mediumProfilePictureUrl:
          mediumProfilePictureUrl ?? this.mediumProfilePictureUrl,
      largeProfilePictureUrl:
          largeProfilePictureUrl ?? this.largeProfilePictureUrl,
      localProfilePicturePath:
          localProfilePicturePath ?? this.localProfilePicturePath,
    );
  }

  ProfilePhoto get profilePhoto {
    final String localPath = localProfilePicturePath.trim();
    if (localPath.isNotEmpty) {
      return ProfilePhoto.local(File(localPath));
    }

    final String mediumUrl = mediumProfilePictureUrl.trim();
    final String largeUrl = largeProfilePictureUrl.trim();
    final String preferredUrl = mediumUrl.isNotEmpty ? mediumUrl : largeUrl;

    if (preferredUrl.isEmpty) {
      return const ProfilePhoto.empty();
    }

    return ProfilePhoto.network(preferredUrl);
  }

  String get resolvedFullName {
    final String normalized = fullName.trim();
    if (normalized.isNotEmpty) {
      return normalized;
    }

    return username;
  }

  String get resolvedBio => bio.trim();

  String get resolvedZoomImageUrl {
    final String largeUrl = largeProfilePictureUrl.trim();
    if (largeUrl.isNotEmpty) {
      return largeUrl;
    }

    return mediumProfilePictureUrl.trim();
  }
}

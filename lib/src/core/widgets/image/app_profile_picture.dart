import 'dart:io';

import 'package:flutter/material.dart';
import 'package:global_airsoft_app/src/core/media/profile_photo.dart';
import 'package:global_airsoft_app/src/core/widgets/app_skeleton.dart';
import 'package:global_airsoft_app/src/core/widgets/image/app_circular_profile_image.dart';
import 'package:global_airsoft_app/src/core/widgets/image/app_profile_image_placeholder.dart';

class AppProfilePicture extends StatelessWidget {
  const AppProfilePicture.network({
    required String imageUrl,
    this.onTap,
    this.size = 126,
    super.key,
  }) : assert(size > 0, 'size must be greater than zero.'),
       _imageUrl = imageUrl,
       _imageProvider = null,
       _profilePhoto = null;

  const AppProfilePicture.imageProvider({
    required ImageProvider imageProvider,
    this.onTap,
    this.size = 126,
    super.key,
  }) : assert(size > 0, 'size must be greater than zero.'),
       _imageUrl = null,
       _imageProvider = imageProvider,
       _profilePhoto = null;

  const AppProfilePicture.profilePhoto({
    required ProfilePhoto profilePhoto,
    this.onTap,
    this.size = 126,
    super.key,
  }) : assert(size > 0, 'size must be greater than zero.'),
       _imageUrl = null,
       _imageProvider = null,
       _profilePhoto = profilePhoto;

  final String? _imageUrl;
  final ImageProvider? _imageProvider;
  final ProfilePhoto? _profilePhoto;
  final VoidCallback? onTap;
  final double size;

  bool get _hasImage {
    final ProfilePhoto? profilePhoto = _profilePhoto;
    if (profilePhoto != null) {
      return profilePhoto.hasPhoto;
    }

    final String? imageUrl = _imageUrl;
    return (imageUrl != null && imageUrl.isNotEmpty) || _imageProvider != null;
  }

  Widget _buildPlaceholder() {
    return AppProfileImagePlaceholder(size: size);
  }

  Widget _buildLoadingSkeleton() {
    return AppSkeleton.circle(size: size);
  }

  Widget _buildImageFromProvider(ImageProvider imageProvider) {
    return Image(
      image: imageProvider,
      fit: BoxFit.cover,
      frameBuilder:
          (
            BuildContext context,
            Widget child,
            int? frame,
            bool wasSynchronouslyLoaded,
          ) {
            if (wasSynchronouslyLoaded || frame != null) {
              return child;
            }

            return _buildLoadingSkeleton();
          },
      errorBuilder:
          (BuildContext context, Object error, StackTrace? stackTrace) {
            return _buildPlaceholder();
          },
    );
  }

  Widget _buildImage() {
    final ProfilePhoto? profilePhoto = _profilePhoto;
    if (profilePhoto != null) {
      if (profilePhoto.isLocal) {
        return _buildImageFromProvider(FileImage(profilePhoto.localFile!));
      }

      if (profilePhoto.isNetwork) {
        return _buildImageFromProvider(NetworkImage(profilePhoto.networkUrl!));
      }

      return _buildPlaceholder();
    }

    final ImageProvider? imageProvider = _imageProvider;
    if (imageProvider != null) {
      return _buildImageFromProvider(imageProvider);
    }

    return _buildImageFromProvider(NetworkImage(_imageUrl!));
  }

  @override
  Widget build(BuildContext context) {
    return AppCircularProfileImage(
      size: size,
      onTap: _hasImage ? onTap : null,
      child: _buildImage(),
    );
  }
}

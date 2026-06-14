import 'package:flutter/material.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/media/profile_photo.dart';
import 'package:global_airsoft_app/src/core/network/remote_image_access_exception.dart';
import 'package:global_airsoft_app/src/core/widgets/app_skeleton.dart';
import 'package:global_airsoft_app/src/core/widgets/image/app_circular_profile_image.dart';
import 'package:global_airsoft_app/src/core/widgets/image/app_profile_image_placeholder.dart';

class AppProfilePicture extends StatelessWidget {
  const AppProfilePicture.network({
    required String imageUrl,
    this.onTap,
    this.onImageLoadFailed,
    this.imageLoadFailureMessageKey = AppLocaleKeys.commonRemoteImageLoadFailed,
    this.size = 126,
    super.key,
  }) : assert(size > 0, 'size must be greater than zero.'),
       _imageUrl = imageUrl,
       _imageProvider = null,
       _profilePhoto = null;

  const AppProfilePicture.imageProvider({
    required ImageProvider imageProvider,
    this.onTap,
    this.onImageLoadFailed,
    this.imageLoadFailureMessageKey = AppLocaleKeys.commonRemoteImageLoadFailed,
    this.size = 126,
    super.key,
  }) : assert(size > 0, 'size must be greater than zero.'),
       _imageUrl = null,
       _imageProvider = imageProvider,
       _profilePhoto = null;

  const AppProfilePicture.profilePhoto({
    required ProfilePhoto profilePhoto,
    this.onTap,
    this.onImageLoadFailed,
    this.imageLoadFailureMessageKey = AppLocaleKeys.commonRemoteImageLoadFailed,
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
  final ValueChanged<RemoteImageAccessException>? onImageLoadFailed;
  final String imageLoadFailureMessageKey;
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

  void _notifyRemoteImageLoadFailed({
    required bool isRemoteImage,
    required Object error,
  }) {
    if (!isRemoteImage || onImageLoadFailed == null) {
      return;
    }

    final RemoteImageAccessException exception =
        error is RemoteImageAccessException
        ? error
        : RemoteImageAccessException(
            message: 'Remote profile image could not be loaded.',
            messageKey: imageLoadFailureMessageKey,
            cause: error,
          );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      onImageLoadFailed?.call(exception);
    });
  }

  Widget _buildImageFromProvider(
    ImageProvider imageProvider, {
    bool isRemoteImage = false,
  }) {
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
            _notifyRemoteImageLoadFailed(
              isRemoteImage: isRemoteImage,
              error: error,
            );
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
        return _buildImageFromProvider(
          NetworkImage(profilePhoto.networkUrl!),
          isRemoteImage: true,
        );
      }

      return _buildPlaceholder();
    }

    final ImageProvider? imageProvider = _imageProvider;
    if (imageProvider != null) {
      return _buildImageFromProvider(imageProvider);
    }

    return _buildImageFromProvider(
      NetworkImage(_imageUrl!),
      isRemoteImage: true,
    );
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

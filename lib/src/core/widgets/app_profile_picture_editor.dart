import 'dart:io';
import 'package:flutter/material.dart';
import 'package:global_airsoft_app/src/core/media/profile_photo.dart';
import 'package:global_airsoft_app/src/core/widgets/app_profile_image_placeholder.dart';
import 'package:global_airsoft_app/src/core/widgets/app_skeleton.dart';

class AppProfilePictureEditor extends StatelessWidget {
  const AppProfilePictureEditor.network({
    required String imageUrl,
    required this.onPhotoTap,
    required this.onEditTap,
    this.size = 126,
    this.badgeSize = 38,
    super.key,
  }) : _imageUrl = imageUrl,
       _imageProvider = null,
       _profilePhoto = null;

  const AppProfilePictureEditor.imageProvider({
    required ImageProvider imageProvider,
    required this.onPhotoTap,
    required this.onEditTap,
    this.size = 126,
    this.badgeSize = 38,
    super.key,
  }) : _imageUrl = null,
       _imageProvider = imageProvider,
       _profilePhoto = null;

  const AppProfilePictureEditor.profilePhoto({
    required ProfilePhoto profilePhoto,
    required this.onPhotoTap,
    required this.onEditTap,
    this.size = 126,
    this.badgeSize = 38,
    super.key,
  }) : _imageUrl = null,
       _imageProvider = null,
       _profilePhoto = profilePhoto;

  final String? _imageUrl;
  final ImageProvider? _imageProvider;
  final ProfilePhoto? _profilePhoto;
  final VoidCallback onPhotoTap;
  final VoidCallback onEditTap;
  final double size;
  final double badgeSize;

  bool get _hasImage {
    if (_profilePhoto != null) {
      return _profilePhoto.hasPhoto;
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

  Widget _buildImage() {
    if (_profilePhoto != null) {
      if (_profilePhoto.isLocal) {
        final File localFile = _profilePhoto.localFile!;
        return Image.file(
          localFile,
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
      } else if (_profilePhoto.isNetwork) {
        final String networkUrl = _profilePhoto.networkUrl!;
        return Image.network(
          networkUrl,
          fit: BoxFit.cover,
          loadingBuilder:
              (
                BuildContext context,
                Widget child,
                ImageChunkEvent? loadingProgress,
              ) {
                if (loadingProgress == null) {
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

      return _buildPlaceholder();
    }

    if (_imageProvider != null) {
      final ImageProvider imageProvider = _imageProvider;

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

    return Image.network(
      _imageUrl!,
      fit: BoxFit.cover,
      loadingBuilder:
          (
            BuildContext context,
            Widget child,
            ImageChunkEvent? loadingProgress,
          ) {
            if (loadingProgress == null) {
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

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Semantics(
      button: true,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _hasImage ? onPhotoTap : null,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.surfaceContainerHighest,
                  border: Border.all(
                    color: colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: ClipOval(child: _buildImage()),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onEditTap,
                child: Container(
                  width: badgeSize,
                  height: badgeSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primary,
                    border: Border.all(color: colorScheme.surface, width: 2),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: 0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.edit_rounded,
                    size: badgeSize * 0.47,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

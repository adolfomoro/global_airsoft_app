import 'package:flutter/material.dart';
import 'package:global_airsoft_app/src/core/media/profile_photo.dart';
import 'package:global_airsoft_app/src/core/widgets/image/app_profile_picture.dart';

class AppProfilePictureEditor extends StatelessWidget {
  const AppProfilePictureEditor.network({
    required String imageUrl,
    required this.onEditTap,
    this.onPhotoTap,
    this.size = 126,
    this.badgeSize = 38,
    super.key,
  }) : assert(size > 0, 'size must be greater than zero.'),
       assert(badgeSize > 0, 'badgeSize must be greater than zero.'),
       _imageUrl = imageUrl,
       _imageProvider = null,
       _profilePhoto = null;

  const AppProfilePictureEditor.imageProvider({
    required ImageProvider imageProvider,
    required this.onEditTap,
    this.onPhotoTap,
    this.size = 126,
    this.badgeSize = 38,
    super.key,
  }) : assert(size > 0, 'size must be greater than zero.'),
       assert(badgeSize > 0, 'badgeSize must be greater than zero.'),
       _imageUrl = null,
       _imageProvider = imageProvider,
       _profilePhoto = null;

  const AppProfilePictureEditor.profilePhoto({
    required ProfilePhoto profilePhoto,
    required this.onEditTap,
    this.onPhotoTap,
    this.size = 126,
    this.badgeSize = 38,
    super.key,
  }) : assert(size > 0, 'size must be greater than zero.'),
       assert(badgeSize > 0, 'badgeSize must be greater than zero.'),
       _imageUrl = null,
       _imageProvider = null,
       _profilePhoto = profilePhoto;

  final String? _imageUrl;
  final ImageProvider? _imageProvider;
  final ProfilePhoto? _profilePhoto;
  final VoidCallback? onPhotoTap;
  final VoidCallback onEditTap;
  final double size;
  final double badgeSize;

  Widget _buildProfilePicture() {
    final ProfilePhoto? profilePhoto = _profilePhoto;
    if (profilePhoto != null) {
      return AppProfilePicture.profilePhoto(
        profilePhoto: profilePhoto,
        onTap: onPhotoTap,
        size: size,
      );
    }

    final ImageProvider? imageProvider = _imageProvider;
    if (imageProvider != null) {
      return AppProfilePicture.imageProvider(
        imageProvider: imageProvider,
        onTap: onPhotoTap,
        size: size,
      );
    }

    return AppProfilePicture.network(
      imageUrl: _imageUrl!,
      onTap: onPhotoTap,
      size: size,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          _buildProfilePicture(),
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
    );
  }
}

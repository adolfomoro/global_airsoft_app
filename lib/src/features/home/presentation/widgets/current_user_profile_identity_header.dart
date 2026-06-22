import 'package:flutter/material.dart';
import 'package:global_airsoft_app/src/app/theme/app_dimensions.dart';
import 'package:global_airsoft_app/src/core/media/profile_photo.dart';
import 'package:global_airsoft_app/src/core/widgets/image/app_profile_image_zoom_viewer.dart';
import 'package:global_airsoft_app/src/core/widgets/image/app_profile_picture.dart';
import 'package:global_airsoft_app/src/features/users/domain/models/user_profile.dart';

class CurrentUserProfileIdentityHeader extends StatelessWidget {
  const CurrentUserProfileIdentityHeader({
    required this.profile,
    required this.photoSize,
    this.showPhoto = true,
    super.key,
  });

  final UserProfile profile;
  final double photoSize;
  final bool showPhoto;

  void _handlePhotoTap(BuildContext context) {
    final ProfilePhoto profilePhoto = profile.profilePhoto;
    if (profilePhoto.isLocal) {
      AppProfileImageZoomViewer.showImageProvider(
        context,
        imageProvider: FileImage(profilePhoto.localFile!),
      );
      return;
    }

    final String zoomImageUrl = profile.resolvedZoomImageUrl;
    if (zoomImageUrl.isEmpty) {
      return;
    }

    AppProfileImageZoomViewer.showNetwork(context, imageUrl: zoomImageUrl);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Column(
      children: <Widget>[
        if (showPhoto) ...<Widget>[
          AppProfilePicture.profilePhoto(
            profilePhoto: profile.profilePhoto,
            onTap: () => _handlePhotoTap(context),
            size: photoSize,
          ),
          const SizedBox(height: AppDimensions.spacingLg),
        ],
        Text(
          profile.resolvedFullName,
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.spacingXs),
        Text(
          '@${profile.username}',
          style: theme.textTheme.titleSmall?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/media/profile_photo.dart';
import 'package:global_airsoft_app/src/core/network/remote_image_access_exception.dart';
import 'package:global_airsoft_app/src/core/widgets/image/app_profile_picture_editor.dart';
import 'package:global_airsoft_app/src/core/widgets/image/profile_photo_selection_bottom_sheet.dart';

class ProfilePhotoNotifier extends Notifier<ProfilePhoto> {
  @override
  ProfilePhoto build() {
    return const ProfilePhoto.empty();
  }

  void setNetworkPhoto(String url) {
    state = ProfilePhoto.network(url);
  }

  void setLocalPhoto(File file) {
    state = ProfilePhoto.local(file);
  }

  void clearPhoto() {
    state = const ProfilePhoto.empty();
  }
}

final profilePhotoProvider =
    NotifierProvider.autoDispose<ProfilePhotoNotifier, ProfilePhoto>(
      ProfilePhotoNotifier.new,
    );

class ProfilePhotoEditor extends StatelessWidget {
  const ProfilePhotoEditor({
    required this.profilePhoto,
    required this.onPhotoChanged,
    this.onPhotoTap,
    this.onImageLoadFailed,
    this.imageLoadFailureMessageKey = AppLocaleKeys.commonRemoteImageLoadFailed,
    this.size = 126,
    this.badgeSize = 38,
    this.enabled = true,
    this.allowDelete = true,
    this.isLoading = false,
    super.key,
  });

  final ProfilePhoto profilePhoto;
  final ValueChanged<ProfilePhoto> onPhotoChanged;
  final VoidCallback? onPhotoTap;
  final ValueChanged<RemoteImageAccessException>? onImageLoadFailed;
  final String imageLoadFailureMessageKey;
  final double size;
  final double badgeSize;
  final bool enabled;
  final bool allowDelete;
  final bool isLoading;

  Future<void> _handleEditTap(BuildContext context) async {
    if (!enabled) {
      return;
    }

    final ProfilePhotoSelectionResult? result =
        await ProfilePhotoSelectionBottomSheet.showForResult(
          context,
          hasCurrentPhoto: profilePhoto.hasPhoto,
          allowDelete: allowDelete,
        );

    if (result == null) return;

    if (result.hasSelectedFile) {
      onPhotoChanged(ProfilePhoto.local(result.file!));
    } else {
      onPhotoChanged(const ProfilePhoto.empty());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppProfilePictureEditor.profilePhoto(
      profilePhoto: profilePhoto,
      onPhotoTap: onPhotoTap,
      onImageLoadFailed: onImageLoadFailed,
      imageLoadFailureMessageKey: imageLoadFailureMessageKey,
      onEditTap: () => _handleEditTap(context),
      size: size,
      badgeSize: badgeSize,
      isLoading: isLoading,
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/core/media/profile_photo.dart';
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
    this.size = 126,
    this.badgeSize = 38,
    super.key,
  });

  final ProfilePhoto profilePhoto;
  final ValueChanged<ProfilePhoto> onPhotoChanged;
  final double size;
  final double badgeSize;

  Future<void> _handleEditTap(BuildContext context) async {
    final ProfilePhotoSelectionResult? result =
        await ProfilePhotoSelectionBottomSheet.showForResult(
          context,
          hasCurrentPhoto: profilePhoto.hasPhoto,
        );

    if (result == null) return;

    if (result.hasSelectedFile) {
      onPhotoChanged(ProfilePhoto.local(result.file!));
    } else {
      onPhotoChanged(const ProfilePhoto.empty());
    }
  }

  void _handlePhotoTap(BuildContext context) {}

  @override
  Widget build(BuildContext context) {
    return AppProfilePictureEditor.profilePhoto(
      profilePhoto: profilePhoto,
      onPhotoTap: () => _handlePhotoTap(context),
      onEditTap: () => _handleEditTap(context),
      size: size,
      badgeSize: badgeSize,
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/core/media/image_crop_service.dart';
import 'package:global_airsoft_app/src/core/media/image_picker_service.dart';
import 'package:global_airsoft_app/src/core/media/media_providers.dart';
import 'package:global_airsoft_app/src/core/media/profile_photo_camera_capture_service.dart';
import 'package:global_airsoft_app/src/core/permissions/camera_permission_service.dart';
import 'package:global_airsoft_app/src/core/permissions/gallery_permission_service.dart';
import 'package:global_airsoft_app/src/core/permissions/permission_providers.dart';

class ProfilePhotoSelectionBottomSheet extends ConsumerWidget {
  const ProfilePhotoSelectionBottomSheet({
    required this.hasCurrentPhoto,
    super.key,
  });

  final bool hasCurrentPhoto;

  static Future<Object?> show(
    BuildContext context, {
    required bool hasCurrentPhoto,
  }) {
    return showModalBottomSheet<Object?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) =>
          ProfilePhotoSelectionBottomSheet(hasCurrentPhoto: hasCurrentPhoto),
    );
  }

  Future<void> _handleTakePhoto(BuildContext context, WidgetRef ref) async {
    final NavigatorState navigator = Navigator.of(context, rootNavigator: true);
    final String cropTitle = context.l10n.tr(
      AppLocaleKeys.profilePhotoCropTitle,
    );
    final CameraPermissionService cameraPermissionService = ref.read(
      cameraPermissionServiceProvider,
    );
    final ProfilePhotoCameraCaptureService cameraCaptureService = ref.read(
      profilePhotoCameraCaptureServiceProvider,
    );
    final ImageCropService imageCropService = ref.read(
      imageCropServiceProvider,
    );

    // Check and request camera permission
    final bool isGranted = await cameraPermissionService.isGranted();

    if (!isGranted) {
      final bool permissionGranted = await cameraPermissionService.request();

      if (!permissionGranted) {
        if (!context.mounted) return;
        await _showPermissionDeniedDialog(
          context,
          isCamera: true,
          onOpenSettings: () async {
            await cameraPermissionService.openSettings();
          },
        );
        return;
      }
    }

    final File? capturedFile = await cameraCaptureService.capture(navigator);

    if (!context.mounted) return;

    if (capturedFile == null) {
      return;
    }

    final File? croppedFile = await imageCropService.cropProfilePhoto(
      context: context,
      sourceFile: capturedFile,
      title: cropTitle,
    );

    if (!context.mounted || croppedFile == null) {
      return;
    }

    Navigator.of(context).pop(croppedFile);
  }

  Future<void> _handleSelectFromGallery(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final GalleryPermissionService galleryPermissionService = ref.read(
      galleryPermissionServiceProvider,
    );
    final ImagePickerService imagePickerService = ref.read(
      imagePickerServiceProvider,
    );
    final ImageCropService imageCropService = ref.read(
      imageCropServiceProvider,
    );

    // Check and request gallery permission
    final bool isGranted = await galleryPermissionService.isGranted();

    if (!isGranted) {
      final bool permissionGranted = await galleryPermissionService.request();

      if (!permissionGranted) {
        if (!context.mounted) return;
        await _showPermissionDeniedDialog(
          context,
          isCamera: false,
          onOpenSettings: () async {
            await galleryPermissionService.openSettings();
          },
        );
        return;
      }
    }

    // Pick image from gallery
    final ImagePickerResult result = await imagePickerService.pickFromGallery(
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (!context.mounted) return;

    if (!result.hasImage) {
      return;
    }

    final File? croppedFile = await imageCropService.cropProfilePhoto(
      context: context,
      sourceFile: result.file!,
      title: context.l10n.tr(AppLocaleKeys.profilePhotoCropTitle),
    );

    if (!context.mounted || croppedFile == null) {
      return;
    }

    Navigator.of(context).pop(croppedFile);
  }

  void _handleDeletePhoto(BuildContext context) {
    Navigator.of(context).pop(const _DeletePhotoResult());
  }

  Future<void> _showPermissionDeniedDialog(
    BuildContext context, {
    required bool isCamera,
    required VoidCallback onOpenSettings,
  }) async {
    final String title = isCamera
        ? context.l10n.tr(AppLocaleKeys.profilePhotoCameraPermissionDeniedTitle)
        : context.l10n.tr(
            AppLocaleKeys.profilePhotoGalleryPermissionDeniedTitle,
          );

    final String message = isCamera
        ? context.l10n.tr(
            AppLocaleKeys.profilePhotoCameraPermissionDeniedMessage,
          )
        : context.l10n.tr(
            AppLocaleKeys.profilePhotoGalleryPermissionDeniedMessage,
          );

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.tr(AppLocaleKeys.profilePhotoCancel)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onOpenSettings();
            },
            child: Text(
              context.l10n.tr(AppLocaleKeys.profilePhotoPermissionOpenSettings),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Drag handle
          const SizedBox(height: 6),
          Center(
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              context.l10n.tr(AppLocaleKeys.profilePhotoSelectPhotoTitle),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Take photo option
          _PhotoOption(
            icon: Icons.camera_alt_rounded,
            label: context.l10n.tr(AppLocaleKeys.profilePhotoTakePhoto),
            iconBackgroundColor: colorScheme.primaryContainer,
            iconColor: colorScheme.onPrimaryContainer,
            onTap: () => _handleTakePhoto(context, ref),
          ),

          const SizedBox(height: 4),

          // Select from gallery option
          _PhotoOption(
            icon: Icons.photo_library_rounded,
            label: context.l10n.tr(AppLocaleKeys.profilePhotoSelectFromGallery),
            iconBackgroundColor: colorScheme.secondaryContainer,
            iconColor: colorScheme.onSecondaryContainer,
            onTap: () => _handleSelectFromGallery(context, ref),
          ),

          // Delete photo option (only if there's a current photo)
          if (hasCurrentPhoto) ...<Widget>[
            const SizedBox(height: 4),
            _PhotoOption(
              icon: Icons.delete_outline_rounded,
              label: context.l10n.tr(AppLocaleKeys.profilePhotoDeletePhoto),
              iconBackgroundColor: colorScheme.errorContainer,
              iconColor: colorScheme.onErrorContainer,
              isDestructive: true,
              onTap: () => _handleDeletePhoto(context),
            ),
          ],

          // Cancel button
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  context.l10n.tr(AppLocaleKeys.profilePhotoCancel),
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoOption extends StatelessWidget {
  const _PhotoOption({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.iconBackgroundColor,
    required this.iconColor,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color iconBackgroundColor;
  final Color iconColor;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    final Color textColor = isDestructive
        ? colorScheme.error
        : colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeletePhotoResult {
  const _DeletePhotoResult();
}

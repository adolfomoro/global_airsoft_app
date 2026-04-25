import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

final class ImageCropService {
  ImageCropService({ImageCropper? imageCropper})
    : _imageCropper = imageCropper ?? ImageCropper();

  final ImageCropper _imageCropper;

  Future<File?> cropProfilePhoto({
    required BuildContext context,
    required File sourceFile,
    required String title,
  }) {
    return cropImage(
      context: context,
      sourceFile: sourceFile,
      title: title,
      aspectRatioPresets: const <CropAspectRatioPreset>[
        CropAspectRatioPreset.square,
      ],
      lockAspectRatio: true,
      showCropGrid: true,
      compressQuality: 92,
    );
  }

  Future<File?> cropImage({
    required BuildContext context,
    required File sourceFile,
    required String title,
    List<CropAspectRatioPreset> aspectRatioPresets =
        const <CropAspectRatioPreset>[CropAspectRatioPreset.square],
    bool lockAspectRatio = true,
    bool showCropGrid = true,
    int compressQuality = 92,
  }) async {
    try {
      if (!sourceFile.existsSync()) {
        return null;
      }

      final ThemeData theme = Theme.of(context);
      final ColorScheme colorScheme = theme.colorScheme;
      final bool isSupportedPlatform =
          kIsWeb ||
          defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS;

      if (!isSupportedPlatform) {
        return sourceFile;
      }

      final CroppedFile? croppedFile = await _imageCropper.cropImage(
        sourcePath: sourceFile.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: compressQuality,
        uiSettings: _buildUiSettings(
          theme: theme,
          colorScheme: colorScheme,
          title: title,
          aspectRatioPresets: aspectRatioPresets,
          lockAspectRatio: lockAspectRatio,
          showCropGrid: showCropGrid,
        ),
      );

      if (croppedFile == null) {
        return null;
      }

      return File(croppedFile.path);
    } catch (_) {
      return null;
    }
  }

  List<PlatformUiSettings> _buildUiSettings({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required String title,
    required List<CropAspectRatioPreset> aspectRatioPresets,
    required bool lockAspectRatio,
    required bool showCropGrid,
  }) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return <PlatformUiSettings>[
        AndroidUiSettings(
          toolbarTitle: title,
          toolbarColor: colorScheme.surface,
          toolbarWidgetColor: colorScheme.onSurface,
          backgroundColor: colorScheme.surface,
          activeControlsWidgetColor: colorScheme.primary,
          dimmedLayerColor: colorScheme.scrim.withValues(alpha: 0.55),
          cropFrameColor: colorScheme.primary,
          cropGridColor: colorScheme.outlineVariant,
          cropGridStrokeWidth: 1,
          cropFrameStrokeWidth: 2,
          showCropGrid: showCropGrid,
          hideBottomControls: false,
          lockAspectRatio: lockAspectRatio,
          initAspectRatio: CropAspectRatioPreset.square,
          aspectRatioPresets: aspectRatioPresets,
          statusBarLight: theme.brightness == Brightness.light,
          navBarLight: theme.brightness == Brightness.light,
        ),
      ];
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return <PlatformUiSettings>[
        IOSUiSettings(
          title: title,
          minimumAspectRatio: 1,
          aspectRatioLockEnabled: lockAspectRatio,
          aspectRatioPresets: aspectRatioPresets,
          resetAspectRatioEnabled: false,
          hidesNavigationBar: false,
          showCancelConfirmationDialog: false,
          showActivitySheetOnDone: false,
          aspectRatioPickerButtonHidden: false,
        ),
      ];
    }

    return const <PlatformUiSettings>[];
  }
}

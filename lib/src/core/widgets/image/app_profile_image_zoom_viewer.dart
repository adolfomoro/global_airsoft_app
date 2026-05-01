import 'package:flutter/material.dart';
import 'package:global_airsoft_app/src/core/widgets/image/app_image_zoom_viewer.dart';

class AppProfileImageZoomViewer extends StatelessWidget {
  const AppProfileImageZoomViewer.network({required String imageUrl, super.key})
    : _imageUrl = imageUrl,
      _imageProvider = null;

  const AppProfileImageZoomViewer.imageProvider({
    required ImageProvider imageProvider,
    super.key,
  }) : _imageUrl = null,
       _imageProvider = imageProvider;

  static Future<T?> showNetwork<T extends Object?>(
    BuildContext context, {
    required String imageUrl,
  }) {
    return AppImageZoomViewer.showNetwork(
      context,
      imageUrl: imageUrl,
      imageShape: AppImageZoomViewerShape.circle,
    );
  }

  static Future<T?> showImageProvider<T extends Object?>(
    BuildContext context, {
    required ImageProvider imageProvider,
  }) {
    return AppImageZoomViewer.showImageProvider(
      context,
      imageProvider: imageProvider,
      imageShape: AppImageZoomViewerShape.circle,
    );
  }

  final String? _imageUrl;
  final ImageProvider? _imageProvider;

  @override
  Widget build(BuildContext context) {
    if (_imageProvider != null) {
      return AppImageZoomViewer.shapedImageProvider(
        imageProvider: _imageProvider,
        imageShape: AppImageZoomViewerShape.circle,
      );
    }

    return AppImageZoomViewer.shapedNetwork(
      imageUrl: _imageUrl!,
      imageShape: AppImageZoomViewerShape.circle,
    );
  }
}

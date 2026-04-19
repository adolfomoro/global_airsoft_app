import 'package:flutter/material.dart';

class AppProfilePictureEditor extends StatelessWidget {
  const AppProfilePictureEditor.network({
    required String imageUrl,
    required this.onPhotoTap,
    required this.onEditTap,
    this.size = 124,
    this.badgeSize = 36,
    super.key,
  }) : _imageUrl = imageUrl,
       _imageProvider = null;

  const AppProfilePictureEditor.imageProvider({
    required ImageProvider imageProvider,
    required this.onPhotoTap,
    required this.onEditTap,
    this.size = 124,
    this.badgeSize = 36,
    super.key,
  }) : _imageUrl = null,
       _imageProvider = imageProvider;

  final String? _imageUrl;
  final ImageProvider? _imageProvider;
  final VoidCallback onPhotoTap;
  final VoidCallback onEditTap;
  final double size;
  final double badgeSize;

  bool get _hasImage {
    final String? imageUrl = _imageUrl;
    return (imageUrl != null && imageUrl.isNotEmpty) || _imageProvider != null;
  }

  Widget _buildFallback(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Container(
      color: colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.account_circle_outlined,
        size: size * 0.58,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    if (_imageProvider != null) {
      return Image(
        image: _imageProvider,
        fit: BoxFit.cover,
        errorBuilder:
            (BuildContext context, Object error, StackTrace? stackTrace) {
              return _buildFallback(context);
            },
      );
    }

    return Image.network(
      _imageUrl!,
      fit: BoxFit.cover,
      errorBuilder:
          (BuildContext context, Object error, StackTrace? stackTrace) {
            return _buildFallback(context);
          },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Semantics(
      button: true,
      label: 'Profile picture',
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
                child: ClipOval(child: _buildImage(context)),
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

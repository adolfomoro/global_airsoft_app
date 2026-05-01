import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppProfileImagePlaceholder extends StatelessWidget {
  static const String _assetPath = 'assets/icons/profile-placeholder.svg';

  const AppProfileImagePlaceholder({required this.size, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return SizedBox.square(
      dimension: size,
      child: SvgPicture.asset(
        _assetPath,
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(
          colorScheme.onSurfaceVariant,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class AppCircularProfileImage extends StatelessWidget {
  const AppCircularProfileImage({
    required this.size,
    required this.child,
    this.onTap,
    super.key,
  }) : assert(size > 0, 'size must be greater than zero.');

  final double size;
  final Widget child;
  final VoidCallback? onTap;

  bool get _isInteractive => onTap != null;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    final Widget content = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.surfaceContainerHighest,
        border: Border.all(color: colorScheme.outlineVariant, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: ClipOval(child: child),
    );

    return Semantics(
      button: _isInteractive,
      child: _isInteractive
          ? GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: content,
            )
          : content,
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppAdaptiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppAdaptiveAppBar({
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle,
    this.automaticallyImplyLeading = true,
    super.key,
  });

  final Widget title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool? centerTitle;
  final bool automaticallyImplyLeading;

  @override
  Size get preferredSize {
    final bool isCupertinoPlatform =
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;

    return Size.fromHeight(
      isCupertinoPlatform ? kMinInteractiveDimensionCupertino : kToolbarHeight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final TargetPlatform platform = Theme.of(context).platform;
    final bool isCupertinoPlatform =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
    final Color backgroundColor = Color.alphaBlend(
      colorScheme.onSurface.withValues(alpha: 0.03),
      colorScheme.surface,
    );
    final Color separatorColor = colorScheme.outlineVariant.withValues(
      alpha: 0.36,
    );

    if (isCupertinoPlatform) {
      return CupertinoNavigationBar(
        middle: DefaultTextStyle.merge(
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
          child: title,
        ),
        leading: leading,
        trailing: _buildCupertinoTrailingActions(actions),
        automaticallyImplyLeading: automaticallyImplyLeading,
        backgroundColor: backgroundColor.withValues(alpha: 0.94),
        border: Border(bottom: BorderSide(color: separatorColor, width: 0)),
      );
    }

    return AppBar(
      title: title,
      actions: actions,
      leading: leading,
      centerTitle: centerTitle ?? false,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: backgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
      shape: Border(bottom: BorderSide(color: separatorColor, width: 0)),
    );
  }

  Widget? _buildCupertinoTrailingActions(List<Widget>? actions) {
    if (actions == null || actions.isEmpty) {
      return null;
    }

    return Row(mainAxisSize: MainAxisSize.min, children: actions);
  }
}

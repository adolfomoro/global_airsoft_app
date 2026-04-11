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
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final TargetPlatform platform = Theme.of(context).platform;
    final bool isCupertinoPlatform =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;

    return AppBar(
      title: title,
      actions: actions,
      leading: leading,
      centerTitle: centerTitle ?? isCupertinoPlatform,
      automaticallyImplyLeading: automaticallyImplyLeading,
    );
  }
}

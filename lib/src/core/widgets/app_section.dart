import 'package:flutter/material.dart';
import 'package:global_airsoft_app/src/app/theme/app_dimensions.dart';

class AppSection extends StatelessWidget {
  const AppSection({
    required this.child,
    super.key,
    this.title,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.titleTextAlign,
    this.titlePadding = const EdgeInsets.only(bottom: AppDimensions.spacingLg),
    this.contentPadding = EdgeInsets.zero,
  });

  final String? title;
  final Widget child;
  final CrossAxisAlignment crossAxisAlignment;
  final TextAlign? titleTextAlign;
  final EdgeInsetsGeometry titlePadding;
  final EdgeInsetsGeometry contentPadding;

  bool get _hasTitle => title != null && title!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: <Widget>[
        if (_hasTitle)
          Padding(
            padding: titlePadding,
            child: Text(
              title!,
              textAlign: titleTextAlign,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        Padding(padding: contentPadding, child: child),
      ],
    );
  }
}

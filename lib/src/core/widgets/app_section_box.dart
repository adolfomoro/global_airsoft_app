import 'package:flutter/material.dart';
import 'package:global_airsoft_app/src/app/theme/app_dimensions.dart';

class AppSectionBox extends StatelessWidget {
  const AppSectionBox({
    required this.child,
    super.key,
    this.title,
    this.backgroundColor,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.titleTextAlign,
  });

  final String? title;
  final Widget child;
  final Color? backgroundColor;
  final CrossAxisAlignment crossAxisAlignment;
  final TextAlign? titleTextAlign;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final bool hasTitle = title != null && title!.trim().isNotEmpty;

    return DecoratedBox(
      decoration: BoxDecoration(
        color:
            backgroundColor ??
            theme.cardTheme.color ??
            colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: crossAxisAlignment,
        children: <Widget>[
          if (hasTitle)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.spacingLg,
                AppDimensions.spacingLg,
                AppDimensions.spacingLg,
                AppDimensions.spacingSm,
              ),
              child: Text(
                title!,
                textAlign: titleTextAlign,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Padding(
            padding: (hasTitle
                ? EdgeInsets.only(bottom: AppDimensions.spacingLg)
                : EdgeInsets.symmetric(vertical: AppDimensions.spacingSm)),
            child: child,
          ),
        ],
      ),
    );
  }
}

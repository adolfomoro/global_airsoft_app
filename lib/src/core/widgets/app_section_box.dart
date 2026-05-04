import 'package:flutter/material.dart';
import 'package:global_airsoft_app/src/app/theme/app_dimensions.dart';

class AppSectionBox extends StatelessWidget {
  const AppSectionBox({
    required this.child,
    super.key,
    this.title,
    this.backgroundColor,
    this.borderRadius = AppDimensions.radiusLg,
    this.titlePadding,
    this.contentPadding,
    this.titleStyle,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.titleTextAlign,
  });

  final String? title;
  final Widget child;
  final Color? backgroundColor;
  final double borderRadius;
  final EdgeInsetsGeometry? titlePadding;
  final EdgeInsetsGeometry? contentPadding;
  final TextStyle? titleStyle;
  final CrossAxisAlignment crossAxisAlignment;
  final TextAlign? titleTextAlign;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final bool hasTitle = title != null && title!.trim().isNotEmpty;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.cardTheme.color ?? colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Column(
        crossAxisAlignment: crossAxisAlignment,
        children: <Widget>[
          if (hasTitle)
            Padding(
              padding:
                  titlePadding ??
                  const EdgeInsets.fromLTRB(
                    AppDimensions.spacingLg,
                    AppDimensions.spacingLg,
                    AppDimensions.spacingLg,
                    AppDimensions.spacingSm,
                  ),
              child: Text(
                title!,
                textAlign: titleTextAlign,
                style:
                    titleStyle ??
                    theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          Padding(
            padding:
                contentPadding ??
                (hasTitle
                    ? const EdgeInsets.fromLTRB(
                        AppDimensions.spacingLg,
                        AppDimensions.spacingSm,
                        AppDimensions.spacingLg,
                        AppDimensions.spacingLg,
                      )
                    : const EdgeInsets.all(AppDimensions.spacingLg)),
            child: child,
          ),
        ],
      ),
    );
  }
}

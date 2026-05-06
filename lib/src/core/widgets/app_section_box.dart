import 'package:flutter/material.dart';
import 'package:global_airsoft_app/src/app/theme/app_dimensions.dart';
import 'package:global_airsoft_app/src/core/widgets/app_section.dart';

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
      child: AppSection(
        title: title,
        crossAxisAlignment: crossAxisAlignment,
        titleTextAlign: titleTextAlign,
        titlePadding: const EdgeInsets.fromLTRB(
          AppDimensions.spacingLg,
          AppDimensions.spacingLg,
          AppDimensions.spacingLg,
          AppDimensions.spacingSm,
        ),
        contentPadding: hasTitle
            ? const EdgeInsets.only(bottom: AppDimensions.spacingLg)
            : const EdgeInsets.symmetric(vertical: AppDimensions.spacingSm),
        child: child,
      ),
    );
  }
}

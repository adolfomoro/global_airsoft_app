import 'package:flutter/material.dart';
import 'package:global_airsoft_app/src/app/theme/app_colors.dart';
import 'package:global_airsoft_app/src/app/theme/app_dimensions.dart';

class AppSettingsRow extends StatelessWidget {
  const AppSettingsRow({
    required this.title,
    required this.trailing,
    super.key,
    this.subtitle,
    this.onTap,
    this.enabled = true,
  });

  final String title;
  final String? subtitle;
  final Widget trailing;
  final VoidCallback? onTap;
  final bool enabled;

  bool get _hasSubtitle => subtitle != null && subtitle!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final bool hasSubtitle = _hasSubtitle;
    final double minHeight = hasSubtitle ? 72 : 56;
    final EdgeInsetsGeometry resolvedPadding = EdgeInsets.symmetric(
      horizontal: AppDimensions.spacingLg,
      vertical: hasSubtitle ? AppDimensions.spacingMd : AppDimensions.spacingLg,
    );
    final Color titleColor = enabled
        ? colorScheme.onSurface
        : colorScheme.onSurfaceVariant;

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: Padding(
            padding: resolvedPadding,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: titleColor,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                        ),
                      ),
                      if (hasSubtitle) ...<Widget>[
                        const SizedBox(height: AppDimensions.spacingXss),
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingLg),
                Align(alignment: Alignment.center, child: trailing),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:global_airsoft_app/src/app/theme/app_colors.dart';
import 'package:global_airsoft_app/src/app/theme/app_dimensions.dart';

enum AppFeedbackMessageVariant { info, success, warning, error }

final class AppFeedbackMessage extends StatelessWidget {
  const AppFeedbackMessage({
    required this.message,
    required this.variant,
    super.key,
    this.title,
    this.supportingText,
  });

  const AppFeedbackMessage.info({
    required String message,
    Key? key,
    String? title,
    String? supportingText,
  }) : this(
         key: key,
         message: message,
         variant: AppFeedbackMessageVariant.info,
         title: title,
         supportingText: supportingText,
       );

  const AppFeedbackMessage.success({
    required String message,
    Key? key,
    String? title,
    String? supportingText,
  }) : this(
         key: key,
         message: message,
         variant: AppFeedbackMessageVariant.success,
         title: title,
         supportingText: supportingText,
       );

  const AppFeedbackMessage.warning({
    required String message,
    Key? key,
    String? title,
    String? supportingText,
  }) : this(
         key: key,
         message: message,
         variant: AppFeedbackMessageVariant.warning,
         title: title,
         supportingText: supportingText,
       );

  const AppFeedbackMessage.error({
    required String message,
    Key? key,
    String? title,
    String? supportingText,
  }) : this(
         key: key,
         message: message,
         variant: AppFeedbackMessageVariant.error,
         title: title,
         supportingText: supportingText,
       );

  final AppFeedbackMessageVariant variant;
  final String? title;
  final String message;
  final String? supportingText;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final _FeedbackPalette palette = _FeedbackPalette.resolve(
      colorScheme,
      variant,
    );
    final String? trimmedTitle = title?.trim();
    final String? trimmedSupportingText = supportingText?.trim();

    return Semantics(
      container: true,
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.backgroundColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          border: Border.all(color: palette.borderColor),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: palette.accentColor.withValues(alpha: 0.08),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingMd),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: 30,
                height: 42,
                child: Icon(
                  palette.icon,
                  color: palette.accentColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (trimmedTitle != null && trimmedTitle.isNotEmpty)
                      Text(
                        trimmedTitle,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: palette.foregroundColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    if (trimmedTitle != null && trimmedTitle.isNotEmpty)
                      const SizedBox(height: AppDimensions.spacingXs),
                    Text(
                      message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: palette.foregroundColor,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (trimmedSupportingText != null &&
                        trimmedSupportingText.isNotEmpty) ...<Widget>[
                      const SizedBox(height: AppDimensions.spacingSm),
                      Text(
                        trimmedSupportingText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: palette.foregroundColor.withValues(
                            alpha: 0.92,
                          ),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _FeedbackPalette {
  const _FeedbackPalette({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.accentColor,
    required this.borderColor,
    required this.icon,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final Color accentColor;
  final Color borderColor;
  final IconData icon;

  static _FeedbackPalette resolve(
    ColorScheme colorScheme,
    AppFeedbackMessageVariant variant,
  ) {
    return switch (variant) {
      AppFeedbackMessageVariant.info => _FeedbackPalette(
        backgroundColor: colorScheme.secondaryContainer,
        foregroundColor: colorScheme.onSecondaryContainer,
        accentColor: AppColors.info,
        borderColor: AppColors.info.withValues(alpha: 0.28),
        icon: Icons.info_outline_rounded,
      ),
      AppFeedbackMessageVariant.success => _FeedbackPalette(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        accentColor: AppColors.success,
        borderColor: AppColors.success.withValues(alpha: 0.24),
        icon: Icons.check_circle_outline_rounded,
      ),
      AppFeedbackMessageVariant.warning => _FeedbackPalette(
        backgroundColor: colorScheme.tertiaryContainer,
        foregroundColor: colorScheme.onTertiaryContainer,
        accentColor: AppColors.warning,
        borderColor: AppColors.warning.withValues(alpha: 0.28),
        icon: Icons.warning_amber_rounded,
      ),
      AppFeedbackMessageVariant.error => _FeedbackPalette(
        backgroundColor: colorScheme.errorContainer,
        foregroundColor: colorScheme.onErrorContainer,
        accentColor: colorScheme.error,
        borderColor: colorScheme.error.withValues(alpha: 0.30),
        icon: Icons.error_outline_rounded,
      ),
    };
  }
}
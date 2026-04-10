import 'package:flutter/material.dart';

enum AppButtonVariant { primary, secondary, tertiary }

final class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    final Color backgroundColor;
    final Color foregroundColor;
    final Color disabledBackgroundColor;
    final Color disabledForegroundColor;

    switch (variant) {
      case AppButtonVariant.primary:
        backgroundColor = colorScheme.primary;
        foregroundColor = colorScheme.onPrimary;
        disabledBackgroundColor = colorScheme.surfaceContainerHighest;
        disabledForegroundColor = colorScheme.onSurfaceVariant;

      case AppButtonVariant.secondary:
        backgroundColor = Colors.transparent;
        foregroundColor = colorScheme.onSurface;
        disabledBackgroundColor = Colors.transparent;
        disabledForegroundColor = colorScheme.onSurfaceVariant;

      case AppButtonVariant.tertiary:
        backgroundColor = colorScheme.surface;
        foregroundColor = colorScheme.onSurface;
        disabledBackgroundColor = colorScheme.surfaceContainerHighest;
        disabledForegroundColor = colorScheme.onSurfaceVariant;
    }

    final bool isDisabled = onPressed == null || isLoading;

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: 48,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDisabled
              ? disabledBackgroundColor
              : backgroundColor,
          foregroundColor: isDisabled
              ? disabledForegroundColor
              : foregroundColor,
          side: variant == AppButtonVariant.secondary
              ? BorderSide(
                  color: isDisabled
                      ? colorScheme.outlineVariant
                      : colorScheme.outline,
                )
              : null,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (icon != null) ...<Widget>[
                    Icon(icon),
                    const SizedBox(width: 8),
                  ],
                  Text(label),
                ],
              ),
      ),
    );
  }
}

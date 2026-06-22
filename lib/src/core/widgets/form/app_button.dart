import 'package:flutter/material.dart';
import 'package:global_airsoft_app/src/app/theme/app_colors.dart';

enum AppButtonVariant { primary, secondary, tertiary }

final class AppButton extends StatelessWidget {
  static const BorderRadius _borderRadius = BorderRadius.all(
    Radius.circular(6),
  );
  static const Size _minimumButtonSize = Size(48, 48);

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.iconWidget,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final Widget? iconWidget;
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
        break;

      case AppButtonVariant.secondary:
        backgroundColor = AppColors.transparent;
        foregroundColor = colorScheme.onSurface;
        disabledBackgroundColor = AppColors.transparent;
        disabledForegroundColor = colorScheme.onSurfaceVariant;
        break;

      case AppButtonVariant.tertiary:
        backgroundColor = colorScheme.surface;
        foregroundColor = colorScheme.onSurface;
        disabledBackgroundColor = colorScheme.surfaceContainerHighest;
        disabledForegroundColor = colorScheme.onSurfaceVariant;
        break;
    }

    final bool isDisabled = onPressed == null || isLoading;
    final Color effectiveForegroundColor = isDisabled
        ? disabledForegroundColor
        : foregroundColor;

    return Semantics(
      button: true,
      enabled: !isDisabled,
      label: label,
      child: SizedBox(
        width: fullWidth ? double.infinity : null,
        height: 48,
        child: ElevatedButton(
          onPressed: isDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            minimumSize: _minimumButtonSize,
            tapTargetSize: MaterialTapTargetSize.padded,
            backgroundColor: isDisabled
                ? disabledBackgroundColor
                : backgroundColor,
            foregroundColor: effectiveForegroundColor,
            side: variant == AppButtonVariant.secondary
                ? BorderSide(
                    color: isDisabled
                        ? colorScheme.outlineVariant
                        : colorScheme.outline,
                  )
                : null,
            shape: const RoundedRectangleBorder(borderRadius: _borderRadius),
          ),
          child: isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      effectiveForegroundColor,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (iconWidget != null || icon != null) ...<Widget>[
                      iconWidget ?? Icon(icon),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

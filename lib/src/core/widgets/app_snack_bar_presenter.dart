import 'package:flutter/material.dart';
import 'package:global_airsoft_app/src/core/network/auth_security_handled_exception.dart';

enum AppSnackBarVariant { info, success, warning, error }

final class AppSnackBarPresenter {
  AppSnackBarPresenter._();

  static const Duration defaultDuration = Duration(seconds: 4);
  static const Duration errorDuration = Duration(seconds: 5);
  static const EdgeInsets _margin = EdgeInsets.fromLTRB(16, 0, 16, 16);
  static const BorderRadius _borderRadius = BorderRadius.all(
    Radius.circular(16),
  );

  static bool showInfo(
    BuildContext context,
    String message, {
    Duration duration = defaultDuration,
    bool replaceCurrent = true,
  }) {
    return _show(
      context,
      message,
      variant: AppSnackBarVariant.info,
      duration: duration,
      replaceCurrent: replaceCurrent,
    );
  }

  static bool showSuccess(
    BuildContext context,
    String message, {
    Duration duration = defaultDuration,
    bool replaceCurrent = true,
  }) {
    return _show(
      context,
      message,
      variant: AppSnackBarVariant.success,
      duration: duration,
      replaceCurrent: replaceCurrent,
    );
  }

  static bool showWarning(
    BuildContext context,
    String message, {
    Duration duration = defaultDuration,
    bool replaceCurrent = true,
  }) {
    return _show(
      context,
      message,
      variant: AppSnackBarVariant.warning,
      duration: duration,
      replaceCurrent: replaceCurrent,
    );
  }

  static bool showError(
    BuildContext context,
    String message, {
    Duration duration = errorDuration,
    bool replaceCurrent = true,
    Object? source,
  }) {
    if (source is AuthSecurityHandledException) {
      return false;
    }

    return _show(
      context,
      message,
      variant: AppSnackBarVariant.error,
      duration: duration,
      replaceCurrent: replaceCurrent,
    );
  }

  static bool _show(
    BuildContext context,
    String message, {
    required AppSnackBarVariant variant,
    required Duration duration,
    required bool replaceCurrent,
  }) {
    final String normalizedMessage = message.trim();
    if (normalizedMessage.isEmpty) {
      return false;
    }

    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(
      context,
    );
    if (messenger == null) {
      return false;
    }

    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final _SnackBarPalette palette = _resolvePalette(colorScheme, variant);
    final TextStyle textStyle =
        theme.snackBarTheme.contentTextStyle?.copyWith(
          color: palette.foregroundColor,
          fontWeight: FontWeight.w500,
        ) ??
        theme.textTheme.bodyMedium?.copyWith(
          color: palette.foregroundColor,
          fontWeight: FontWeight.w500,
        ) ??
        TextStyle(color: palette.foregroundColor, fontWeight: FontWeight.w500);

    if (replaceCurrent) {
      messenger.hideCurrentSnackBar();
    }

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: palette.backgroundColor,
        margin: _margin,
        shape: RoundedRectangleBorder(borderRadius: _borderRadius),
        duration: duration,
        content: _AppSnackBarContent(
          icon: palette.iconData,
          message: normalizedMessage,
          foregroundColor: palette.foregroundColor,
          textStyle: textStyle,
        ),
      ),
    );

    return true;
  }

  static _SnackBarPalette _resolvePalette(
    ColorScheme colorScheme,
    AppSnackBarVariant variant,
  ) {
    return switch (variant) {
      AppSnackBarVariant.info => _SnackBarPalette(
        backgroundColor: colorScheme.secondaryContainer,
        foregroundColor: colorScheme.onSecondaryContainer,
        iconData: Icons.info_outline,
      ),
      AppSnackBarVariant.success => _SnackBarPalette(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        iconData: Icons.check_circle_outline,
      ),
      AppSnackBarVariant.warning => _SnackBarPalette(
        backgroundColor: colorScheme.tertiaryContainer,
        foregroundColor: colorScheme.onTertiaryContainer,
        iconData: Icons.warning_amber_outlined,
      ),
      AppSnackBarVariant.error => _SnackBarPalette(
        backgroundColor: colorScheme.errorContainer,
        foregroundColor: colorScheme.onErrorContainer,
        iconData: Icons.error_outline,
      ),
    };
  }
}

extension AppSnackBarBuildContextX on BuildContext {
  bool showInfoSnackBar(
    String message, {
    Duration duration = AppSnackBarPresenter.defaultDuration,
    bool replaceCurrent = true,
  }) {
    return AppSnackBarPresenter.showInfo(
      this,
      message,
      duration: duration,
      replaceCurrent: replaceCurrent,
    );
  }

  bool showSuccessSnackBar(
    String message, {
    Duration duration = AppSnackBarPresenter.defaultDuration,
    bool replaceCurrent = true,
  }) {
    return AppSnackBarPresenter.showSuccess(
      this,
      message,
      duration: duration,
      replaceCurrent: replaceCurrent,
    );
  }

  bool showWarningSnackBar(
    String message, {
    Duration duration = AppSnackBarPresenter.defaultDuration,
    bool replaceCurrent = true,
  }) {
    return AppSnackBarPresenter.showWarning(
      this,
      message,
      duration: duration,
      replaceCurrent: replaceCurrent,
    );
  }

  bool showErrorSnackBar(
    String message, {
    Duration duration = AppSnackBarPresenter.errorDuration,
    bool replaceCurrent = true,
    Object? source,
  }) {
    return AppSnackBarPresenter.showError(
      this,
      message,
      duration: duration,
      replaceCurrent: replaceCurrent,
      source: source,
    );
  }
}

final class _SnackBarPalette {
  const _SnackBarPalette({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.iconData,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final IconData iconData;
}

final class _AppSnackBarContent extends StatelessWidget {
  const _AppSnackBarContent({
    required this.icon,
    required this.message,
    required this.foregroundColor,
    required this.textStyle,
  });

  final IconData icon;
  final String message;
  final Color foregroundColor;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, color: foregroundColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: textStyle,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

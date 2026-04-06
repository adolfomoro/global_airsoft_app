import 'package:flutter/material.dart';

/// Helper para SnackBars consistentes
abstract final class SnackBarHelper {
  static const Duration defaultDuration = Duration(milliseconds: 3000);

  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = defaultDuration,
  }) {
    _show(context, message, Colors.green, duration);
  }

  static void showError(
    BuildContext context,
    String message, {
    Duration duration = defaultDuration,
  }) {
    _show(context, message, Colors.red, duration);
  }

  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = defaultDuration,
  }) {
    _show(context, message, Colors.blue, duration);
  }

  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = defaultDuration,
  }) {
    _show(context, message, Colors.orange, duration);
  }

  static void _show(
    BuildContext context,
    String message,
    Color backgroundColor,
    Duration duration,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
      ),
    );
  }
}

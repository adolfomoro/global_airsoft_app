import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

final class AppConfirmationDialog {
  const AppConfirmationDialog._();

  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmLabel,
    required String cancelLabel,
    bool isDestructive = false,
    bool barrierDismissible = false,
  }) {
    if (!context.mounted) {
      return Future<bool>.value(false);
    }

    final ThemeData theme = Theme.of(context);
    final NavigatorState navigator = Navigator.of(context, rootNavigator: true);
    final TargetPlatform platform = theme.platform;
    final bool isCupertinoPlatform =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;

    final Future<bool?> result = showAdaptiveDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext _) {
        if (isCupertinoPlatform) {
          return CupertinoAlertDialog(
            title: Text(title),
            content: Text(message),
            actions: <Widget>[
              CupertinoDialogAction(
                onPressed: () => navigator.pop(false),
                child: Text(cancelLabel),
              ),
              CupertinoDialogAction(
                isDestructiveAction: isDestructive,
                onPressed: () => navigator.pop(true),
                child: Text(confirmLabel),
              ),
            ],
          );
        }

        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => navigator.pop(false),
              child: Text(cancelLabel),
            ),
            TextButton(
              onPressed: () => navigator.pop(true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );

    return result.then((bool? value) => value ?? false);
  }
}

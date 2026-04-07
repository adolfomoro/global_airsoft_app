import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/providers/device_providers.dart';
import '../dialogs/request_notification_permission_dialog.dart';
import '../providers/notification_permission_provider.dart';

class NotificationPermissionListener extends ConsumerStatefulWidget {
  const NotificationPermissionListener({
    required this.child,
    required this.navigatorKey,
    super.key,
  });

  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  ConsumerState<NotificationPermissionListener> createState() =>
      _NotificationPermissionListenerState();
}

class _NotificationPermissionListenerState
    extends ConsumerState<NotificationPermissionListener> {
  bool _isDialogOpen = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<NotificationPermissionAction>>(
      notificationPermissionManagerProvider,
      (previous, next) {
        next.whenData((action) async {
          if (action == NotificationPermissionAction.none || _isDialogOpen) {
            return;
          }
          if (!mounted) {
            return;
          }
          await _handleAction(action);
        });
      },
    );

    return widget.child;
  }

  Future<void> _handleAction(NotificationPermissionAction action) async {
    _isDialogOpen = true;
    try {
      if (action == NotificationPermissionAction.showOpenSettings) {
        await _showOpenSettingsDialog();
      } else {
        await _showPermissionDialog();
      }
    } finally {
      _isDialogOpen = false;
    }
  }

  Future<void> _showPermissionDialog() async {
    final permissionService = await ref.read(
      notificationPermissionServiceProvider.future,
    );
    await permissionService.markPromptShown();

    if (!mounted) {
      return;
    }

    final navigatorState = widget.navigatorKey.currentState;
    if (navigatorState == null || !navigatorState.mounted) {
      return;
    }

    final didAllow = await showDialog<bool>(
      context: navigatorState.context,
      barrierDismissible: false,
      builder: (context) {
        return RequestNotificationPermissionDialog(
          onAllow: () {
            Navigator.of(context).pop(true);
          },
          onDismiss: () {
            Navigator.of(context).pop(false);
          },
        );
      },
    );

    if (didAllow != true) {
      return;
    }

    try {
      final tokenService = ref.read(fcmPushTokenServiceProvider);
      await tokenService.initialize();
      final status = await tokenService.getAuthorizationStatus();
      if (status == AuthorizationStatus.authorized ||
          status == AuthorizationStatus.provisional) {
        await permissionService.markPermissionGranted();
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      final navigatorState = widget.navigatorKey.currentState;
      if (navigatorState == null || !navigatorState.mounted) {
        return;
      }
      ScaffoldMessenger.of(navigatorState.context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao habilitar notificações'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _showOpenSettingsDialog() async {
    final permissionService = await ref.read(
      notificationPermissionServiceProvider.future,
    );
    await permissionService.markPromptShown();

    if (!mounted) {
      return;
    }

    final navigatorState = widget.navigatorKey.currentState;
    if (navigatorState == null || !navigatorState.mounted) {
      return;
    }

    final openSettings = await showDialog<bool>(
      context: navigatorState.context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Notificações desativadas'),
          content: const Text(
            'Para receber alertas de amizades, jogos e convites de times, ative as notificações nas configurações do aparelho.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Agora Não'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Abrir Configurações'),
            ),
          ],
        );
      },
    );

    if (openSettings == true) {
      await openAppSettings();
    }
  }
}

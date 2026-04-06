import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/providers/device_providers.dart';
import '../../../../core/services/fcm_push_token_service.dart';
import '../dialogs/request_notification_permission_dialog.dart';
import '../providers/notification_permission_provider.dart';

class NotificationPermissionListener extends ConsumerStatefulWidget {
  const NotificationPermissionListener({
    required this.child,
    super.key,
  });

  final Widget child;

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
          if (context.mounted) {
            await _handleAction(context, action);
          }
        });
      },
    );

    return widget.child;
  }

  Future<void> _handleAction(
    BuildContext context,
    NotificationPermissionAction action,
  ) async {
    _isDialogOpen = true;
    try {
      if (action == NotificationPermissionAction.showOpenSettings) {
        await _showOpenSettingsDialog(context);
      } else {
        await _showPermissionDialog(context);
      }
    } finally {
      _isDialogOpen = false;
    }
  }

  Future<void> _showPermissionDialog(BuildContext context) async {
    final permissionService = await ref.read(
      notificationPermissionServiceProvider.future,
    );
    await permissionService.markPromptShown();

    final didAllow = await showDialog<bool>(
      context: context,
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao habilitar notificações'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _showOpenSettingsDialog(BuildContext context) async {
    final permissionService = await ref.read(
      notificationPermissionServiceProvider.future,
    );
    await permissionService.markPromptShown();

    final openSettings = await showDialog<bool>(
      context: context,
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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../../core/providers/device_providers.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';

enum NotificationPermissionAction { none, showPrePrompt, showOpenSettings }

final notificationPermissionManagerProvider =
    FutureProvider<NotificationPermissionAction>((ref) async {
      final permissionService = await ref.watch(
        notificationPermissionServiceProvider.future,
      );
      final tokenService = ref.watch(fcmPushTokenServiceProvider);
      final authState = ref.watch(
        authNotifierProvider.select((state) => state.isLoggedIn),
      );

      final status = await tokenService.getAuthorizationStatus();
      if (status == AuthorizationStatus.authorized ||
          status == AuthorizationStatus.provisional) {
        if (!permissionService.hasPermissionBeenGranted()) {
          await permissionService.markPermissionGranted();
        }
        return NotificationPermissionAction.none;
      }

      final shouldAsk = permissionService.shouldRequestPermission(
        isLoggedIn: authState,
      );
      if (!shouldAsk) {
        return NotificationPermissionAction.none;
      }

      if (status == AuthorizationStatus.denied) {
        return NotificationPermissionAction.showOpenSettings;
      }

      return NotificationPermissionAction.showPrePrompt;
    });

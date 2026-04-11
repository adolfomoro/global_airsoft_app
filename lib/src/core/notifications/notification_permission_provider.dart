import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/app/app_providers.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:permission_handler/permission_handler.dart';

enum NotificationPermissionAction { none, showPrePrompt, showOpenSettings }

final FutureProvider<NotificationPermissionAction>
notificationPermissionManagerProvider =
    FutureProvider<NotificationPermissionAction>((Ref ref) async {
      final notificationPermissionService = ref.watch(
        notificationPermissionServiceProvider,
      );
      final pushNotificationService = ref.watch(
        pushNotificationServiceProvider,
      );
      final bool isAuthenticated = ref.watch(isAuthenticatedProvider);

      final AuthorizationStatus status = await pushNotificationService
          .getAuthorizationStatus();
      if (status == AuthorizationStatus.authorized ||
          status == AuthorizationStatus.provisional) {
        if (!notificationPermissionService.hasPermissionBeenGranted()) {
          await notificationPermissionService.markPermissionGranted();
        }

        return NotificationPermissionAction.none;
      }

      final bool shouldAsk = notificationPermissionService
          .shouldRequestPermission(isLoggedIn: isAuthenticated);
      if (!shouldAsk) {
        return NotificationPermissionAction.none;
      }

      if (status == AuthorizationStatus.notDetermined) {
        return NotificationPermissionAction.showPrePrompt;
      }

      if (status == AuthorizationStatus.denied) {
        if (Platform.isIOS) {
          return NotificationPermissionAction.showOpenSettings;
        }

        final PermissionStatus osStatus = await Permission.notification.status;
        if (osStatus == PermissionStatus.permanentlyDenied ||
            osStatus == PermissionStatus.restricted) {
          return NotificationPermissionAction.showOpenSettings;
        }

        if (!notificationPermissionService.hasSystemPermissionBeenRequested()) {
          return NotificationPermissionAction.showPrePrompt;
        }

        final bool canShowDialogAgain =
            await Permission.notification.shouldShowRequestRationale;
        if (canShowDialogAgain) {
          return NotificationPermissionAction.showPrePrompt;
        }

        return NotificationPermissionAction.showOpenSettings;
      }

      return NotificationPermissionAction.showPrePrompt;
    });

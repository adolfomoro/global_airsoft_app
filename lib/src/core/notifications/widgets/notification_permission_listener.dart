import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/app/app_providers.dart';
import 'package:global_airsoft_app/src/core/logging/app_logger.dart';
import 'package:global_airsoft_app/src/core/notifications/notification_permission_provider.dart';
import 'package:global_airsoft_app/src/core/notifications/notification_permission_service.dart';
import 'package:global_airsoft_app/src/core/notifications/push_notification_service.dart';
import 'package:global_airsoft_app/src/core/notifications/widgets/request_notification_permission_screen.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:permission_handler/permission_handler.dart';

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
    extends ConsumerState<NotificationPermissionListener>
    with WidgetsBindingObserver {
  bool _isDialogOpen = false;
  bool _isOpeningSettings = false;
  Completer<void>? _resumeCompleter;
  ProviderSubscription<AsyncValue<NotificationPermissionAction>>?
  _permissionActionSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _permissionActionSubscription = ref
        .listenManual<AsyncValue<NotificationPermissionAction>>(
          notificationPermissionManagerProvider,
          (
            AsyncValue<NotificationPermissionAction>? previous,
            AsyncValue<NotificationPermissionAction> next,
          ) {
            next.whenData((NotificationPermissionAction action) {
              unawaited(_handleNextAction(action));
            });
          },
        );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _resumeCompleter?.complete();
    _resumeCompleter = null;
    _permissionActionSubscription?.close();
    _permissionActionSubscription = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resumeCompleter?.complete();
      _resumeCompleter = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  Future<void> _handleNextAction(NotificationPermissionAction action) async {
    if (!mounted || action == NotificationPermissionAction.none) {
      return;
    }

    if (_isDialogOpen) {
      return;
    }

    try {
      await _handleAction(action);
    } catch (error, stackTrace) {
      AppLogger.instance.error(
        'Notification permission flow failed.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _handleAction(NotificationPermissionAction action) async {
    _isDialogOpen = true;
    try {
      if (action == NotificationPermissionAction.showOpenSettings) {
        await _showOpenSettingsDialog();
        return;
      }

      await _showPermissionDialog();
    } finally {
      _isDialogOpen = false;
    }
  }

  Future<void> _showPermissionDialog() async {
    final notificationPermissionService = ref.read(
      notificationPermissionServiceProvider,
    );
    final PushNotificationService pushNotificationService = ref.read(
      pushNotificationServiceProvider,
    );
    await notificationPermissionService.markPromptShown();

    final NavigatorState? navigatorState = widget.navigatorKey.currentState;
    if (navigatorState == null || !navigatorState.mounted) {
      return;
    }

    final bool? didAllow = await navigatorState.push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (BuildContext _) {
          return RequestNotificationPermissionScreen(
            onAllow: () {
              unawaited(
                _requestSystemPermissionAndCloseScreen(
                  navigatorState: navigatorState,
                  pushNotificationService: pushNotificationService,
                  notificationPermissionService: notificationPermissionService,
                ),
              );
            },
            onDismiss: () => navigatorState.pop(false),
          );
        },
      ),
    );

    if (didAllow == null) {
      return;
    }

    if (didAllow != true) {
      return;
    }
  }

  Future<void> _requestSystemPermissionAndCloseScreen({
    required NavigatorState navigatorState,
    required PushNotificationService pushNotificationService,
    required NotificationPermissionService notificationPermissionService,
  }) async {
    try {
      await notificationPermissionService.markSystemPermissionRequested();
      final NotificationSettings settings = await pushNotificationService
          .requestPermissions();
      final bool granted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      if (granted) {
        await notificationPermissionService.markPermissionGranted();
      }

      if (!mounted || !navigatorState.mounted) {
        return;
      }

      navigatorState.pop(granted);
    } catch (error, stackTrace) {
      AppLogger.instance.error(
        'Notification permission result could not be applied.',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted || !navigatorState.mounted) {
        return;
      }

      navigatorState.pop(null);
    }
  }

  Future<void> _showOpenSettingsDialog() async {
    final notificationPermissionService = ref.read(
      notificationPermissionServiceProvider,
    );
    final PushNotificationService pushNotificationService = ref.read(
      pushNotificationServiceProvider,
    );
    await notificationPermissionService.markPromptShown();

    final NavigatorState? navigatorState = widget.navigatorKey.currentState;
    if (navigatorState == null || !navigatorState.mounted) {
      return;
    }

    final bool? openSettings = await navigatorState.push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (BuildContext _) {
          return RequestNotificationPermissionScreen(
            mode: NotificationPermissionScreenMode.openSettings,
            onAllow: () {
              unawaited(
                _openSettingsAndCloseWhenGranted(
                  navigatorState: navigatorState,
                  pushNotificationService: pushNotificationService,
                  notificationPermissionService: notificationPermissionService,
                ),
              );
            },
            onDismiss: () => navigatorState.pop(false),
          );
        },
      ),
    );

    if (openSettings == true) {
      return;
    }

    final bool isAuthenticated = ref.read(isAuthenticatedProvider);
    if (isAuthenticated) {
      await notificationPermissionService.deferOpenSettingsPromptForLoggedIn(
        reopenCount: 2,
      );
    }
  }

  Future<void> _openSettingsAndCloseWhenGranted({
    required NavigatorState navigatorState,
    required PushNotificationService pushNotificationService,
    required NotificationPermissionService notificationPermissionService,
  }) async {
    if (_isOpeningSettings) {
      return;
    }

    _isOpeningSettings = true;
    try {
      final bool opened = await openAppSettings();
      if (!opened || !mounted || !navigatorState.mounted) {
        return;
      }

      await _waitForNextResume();
      if (!mounted || !navigatorState.mounted) {
        return;
      }

      final AuthorizationStatus status = await pushNotificationService
          .getAuthorizationStatus();
      final bool granted =
          status == AuthorizationStatus.authorized ||
          status == AuthorizationStatus.provisional;
      if (!granted) {
        return;
      }

      await notificationPermissionService.markPermissionGranted();
      if (!mounted || !navigatorState.mounted) {
        return;
      }

      navigatorState.pop(true);
    } catch (error, stackTrace) {
      AppLogger.instance.error(
        'Open settings permission flow failed.',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _isOpeningSettings = false;
    }
  }

  Future<void> _waitForNextResume() async {
    final Completer<void> completer = Completer<void>();
    _resumeCompleter = completer;
    await completer.future;
    if (identical(_resumeCompleter, completer)) {
      _resumeCompleter = null;
    }
  }
}

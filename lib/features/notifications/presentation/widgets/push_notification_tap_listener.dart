import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/push_notification_tap_event.dart';
import '../providers/push_notification_runtime_provider.dart';

typedef PushNotificationTapHandler =
    FutureOr<void> Function(PushNotificationTapEvent event);

class PushNotificationTapListener extends ConsumerStatefulWidget {
  const PushNotificationTapListener({
    required this.child,
    this.onTap,
    super.key,
  });

  final Widget child;
  final PushNotificationTapHandler? onTap;

  @override
  ConsumerState<PushNotificationTapListener> createState() =>
      _PushNotificationTapListenerState();
}

class _PushNotificationTapListenerState
    extends ConsumerState<PushNotificationTapListener> {
  StreamSubscription<PushNotificationTapEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    final runtime = ref.read(pushNotificationRuntimeServiceProvider);
    _subscription = runtime.tapEvents.listen(_handleTapEvent);
  }

  Future<void> _handleTapEvent(PushNotificationTapEvent event) async {
    final handler = widget.onTap;
    if (handler != null) {
      await handler(event);
      return;
    }

    _defaultTapHandler(event);
  }

  void _defaultTapHandler(PushNotificationTapEvent event) {
    assert(() {
      debugPrint(
        'Push tap received (messageId=${event.messageId}, '
        'terminated=${event.openedFromTerminated}, payload=${event.payload})',
      );
      return true;
    }());
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

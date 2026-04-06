import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/push_notification_runtime_service.dart';

final pushNotificationRuntimeServiceProvider =
    Provider<PushNotificationRuntimeService>((ref) {
      final service = PushNotificationRuntimeService();
      ref.onDispose(() {
        service.dispose();
      });
      return service;
    });

Future<void> initializePushNotificationRuntime(ProviderContainer container) async {
  final runtime = container.read(pushNotificationRuntimeServiceProvider);

  try {
    await runtime.initialize();
  } catch (e) {
    assert(() {
      debugPrint('Push runtime bootstrap failed: $e');
      return true;
    }());
  }
}

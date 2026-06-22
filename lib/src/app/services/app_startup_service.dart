import 'package:global_airsoft_app/src/core/logging/app_logger.dart';
import 'package:global_airsoft_app/src/core/notifications/push_notification_service.dart';
import 'package:global_airsoft_app/src/features/device/application/services/device_registration_service.dart';

abstract interface class AppStartupServiceContract {
  Future<void> initializeCriticalState();

  Future<void> initializeBackgroundServices();
}

final class AppStartupService implements AppStartupServiceContract {
  AppStartupService({
    required DeviceRegistrationService deviceRegistrationService,
    required PushNotificationService pushNotificationService,
    required void Function(String token) onPushTokenReceived,
    required AppLogger logger,
  }) : _deviceRegistrationService = deviceRegistrationService,
       _pushNotificationService = pushNotificationService,
       _onPushTokenReceived = onPushTokenReceived,
       _logger = logger;

  final DeviceRegistrationService _deviceRegistrationService;
  final PushNotificationService _pushNotificationService;
  final void Function(String token) _onPushTokenReceived;
  final AppLogger _logger;

  Future<void> initializeCriticalState() async {
    await _deviceRegistrationService.initialize();
  }

  Future<void> initializeBackgroundServices() async {
    try {
      await _pushNotificationService.initialize(
        onTokenUpdated: (String token) async {
          _onPushTokenReceived(token);
          await _deviceRegistrationService.registerInBackground();
        },
      );
    } catch (error, stackTrace) {
      _logger.error(
        'Background startup services initialization failed.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}

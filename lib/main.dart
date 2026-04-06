import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/device_providers.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_screen_background.dart';
import 'core/widgets/app_unfocus_wrapper.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/notifications/presentation/providers/push_notification_runtime_provider.dart';
import 'features/notifications/presentation/widgets/notification_permission_listener.dart';
import 'features/notifications/presentation/widgets/push_notification_tap_listener.dart';

late ProviderContainer _globalContainer;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  _globalContainer = ProviderContainer();
  await initializePushNotificationRuntime(_globalContainer);
  await initializeDeviceService(_globalContainer);
  await initializePushTokenMonitoring(_globalContainer);
  await _markAppOpened();

  runApp(
    UncontrolledProviderScope(
      container: _globalContainer,
      child: const MyApp(),
    ),
  );
}

Future<void> _markAppOpened() async {
  try {
    final permissionService = await _globalContainer.read(
      notificationPermissionServiceProvider.future,
    );
    await permissionService.markAppOpened();
  } catch (e) {
    assert(() {
      debugPrint('Error marking app opened: $e');
      return true;
    }());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Global Airsoft App',
      theme: AppTheme.dark,
      builder: (context, child) {
        return PushNotificationTapListener(
          child: NotificationPermissionListener(
            child: AppUnfocusWrapper(
              child: AppScreenBackground(
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
      home: const LoginPage(),
    );
  }
}

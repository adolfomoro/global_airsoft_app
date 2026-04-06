import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/device_providers.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_screen_background.dart';
import 'core/widgets/app_unfocus_wrapper.dart';
import 'features/auth/presentation/pages/login_page.dart';

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
  await initializeDeviceService(_globalContainer);
  await initializePushTokenMonitoring(_globalContainer);

  runApp(
    UncontrolledProviderScope(
      container: _globalContainer,
      child: const MyApp(),
    ),
  );
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
        return AppUnfocusWrapper(
          child: AppScreenBackground(child: child ?? const SizedBox.shrink()),
        );
      },
      home: const LoginPage(),
    );
  }
}

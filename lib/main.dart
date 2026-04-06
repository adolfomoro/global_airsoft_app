import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/device_providers.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_screen_background.dart';
import 'core/widgets/app_unfocus_wrapper.dart';
import 'features/auth/presentation/pages/login_page.dart';

// Global container to access initialized services anywhere
late ProviderContainer _globalContainer;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Edge-to-edge UI setup (Android & iOS)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Overlay style customization for both platforms
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      // iOS specific (safe for Android to ignore)
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  // Portrait orientation only for better mobile UX
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // FAST initialization: device service loads synchronously
  _globalContainer = ProviderContainer();
  await initializeDeviceService(_globalContainer);

  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Global Airsoft App',
      // Dark mode only - always
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

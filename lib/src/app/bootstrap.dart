import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:global_airsoft_app/src/app/theme/app_theme.dart';
import 'package:global_airsoft_app/src/core/logging/app_logger.dart';
import 'package:global_airsoft_app/src/core/monitoring/app_telemetry.dart';

typedef AppBuilder = Future<BootstrapPayload> Function();

final class BootstrapPayload {
  const BootstrapPayload({required this.app, required this.initialBrightness});

  final Widget app;
  final Brightness initialBrightness;
}

Future<void> bootstrap({required AppBuilder builder}) async {
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (FlutterErrorDetails details) {
        AppLogger.instance.flutterError(details);
        AppTelemetry.instance.reportFlutterError(details);
      };

      PlatformDispatcher.instance.onError =
          (Object error, StackTrace stackTrace) {
            AppLogger.instance.error(
              'Unhandled platform error',
              error: error,
              stackTrace: stackTrace,
            );
            AppTelemetry.instance.reportPlatformError(error, stackTrace);
            return true;
          };

      final BootstrapPayload payload;
      try {
        payload = await builder();
      } catch (error, stackTrace) {
        AppLogger.instance.error(
          'Startup builder failed',
          error: error,
          stackTrace: stackTrace,
        );
        runApp(const _StartupFallbackApp());
        return;
      }

      _configureSystemUi(payload.initialBrightness);
      runApp(payload.app);
    },
    (Object error, StackTrace stackTrace) {
      AppLogger.instance.error(
        'Unhandled zone error',
        error: error,
        stackTrace: stackTrace,
      );
    },
  );
}

void _configureSystemUi(Brightness brightness) {
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(AppTheme.overlayStyleFor(brightness));
}

class _StartupFallbackApp extends StatelessWidget {
  const _StartupFallbackApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'App startup failed. Please restart the application.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

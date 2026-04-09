import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:global_airsoft_app/src/app/theme/app_theme.dart';
import 'package:global_airsoft_app/src/core/logging/app_logger.dart';

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
      };

      PlatformDispatcher.instance.onError =
          (Object error, StackTrace stackTrace) {
            AppLogger.instance.error(
              'Unhandled platform error',
              error: error,
              stackTrace: stackTrace,
            );
            return true;
          };

      final BootstrapPayload payload = await builder();
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

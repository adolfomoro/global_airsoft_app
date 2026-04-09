import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:global_airsoft_app/src/app/theme/app_theme.dart';
import 'package:global_airsoft_app/src/core/logging/app_logger.dart';

typedef AppBuilder = Widget Function();

Future<void> bootstrap({required AppBuilder builder}) async {
  WidgetsFlutterBinding.ensureInitialized();
  _configureSystemUi();

  FlutterError.onError = (FlutterErrorDetails details) {
    AppLogger.instance.flutterError(details);
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stackTrace) {
    AppLogger.instance.error(
      'Unhandled platform error',
      error: error,
      stackTrace: stackTrace,
    );
    return true;
  };

  await runZonedGuarded<Future<void>>(
    () async {
      runApp(builder());
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

void _configureSystemUi() {
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    AppTheme.overlayStyleFor(Brightness.light),
  );
}

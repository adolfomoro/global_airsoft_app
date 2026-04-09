import 'package:flutter/foundation.dart';

final class AppLogger {
  AppLogger._();

  static final AppLogger instance = AppLogger._();

  void info(String message) {
    if (kDebugMode) {
      debugPrint('[INFO] $message');
    }
  }

  void error(String message, {Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      debugPrint('[ERROR] $message');
      if (error != null) {
        debugPrint('[ERROR_TYPE] ${error.runtimeType}');
      }
      if (stackTrace != null) {
        final List<String> traceLines = stackTrace.toString().split('\n');
        final int maxLines = traceLines.length < 5 ? traceLines.length : 5;
        debugPrint(traceLines.take(maxLines).join('\n'));
      }
    }
  }

  void flutterError(FlutterErrorDetails details) {
    error(
      details.exceptionAsString(),
      error: details.exception,
      stackTrace: details.stack,
    );
  }
}

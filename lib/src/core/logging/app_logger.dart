import 'package:flutter/foundation.dart';

typedef AppLoggerRemoteErrorReporter =
    void Function(
      String message, {
      Object? error,
      StackTrace? stackTrace,
      Map<String, Object?> attributes,
    });

typedef AppLoggerRemoteInfoReporter = void Function(String message);

final class AppLogger {
  AppLogger._();

  static final AppLogger instance = AppLogger._();

  AppLoggerRemoteErrorReporter? _remoteErrorReporter;
  AppLoggerRemoteInfoReporter? _remoteInfoReporter;

  void setRemoteInfoReporter(AppLoggerRemoteInfoReporter? reporter) {
    _remoteInfoReporter = reporter;
  }

  void setRemoteErrorReporter(AppLoggerRemoteErrorReporter? reporter) {
    _remoteErrorReporter = reporter;
  }

  void info(String message) {
    if (kDebugMode) {
      debugPrint('[INFO] $message');
    }

    _invokeRemoteInfoReporter(message);
  }

  void debug(String message) {
    if (kDebugMode) {
      debugPrint('[DEBUG] $message');
    }
  }

  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> attributes = const <String, Object?>{},
  }) {
    if (kDebugMode) {
      debugPrint('[ERROR] $message');
      if (error != null) {
        debugPrint('[ERROR_TYPE] ${error.runtimeType}');
      }
      if (attributes.isNotEmpty) {
        debugPrint('[ERROR_ATTRIBUTES] $attributes');
      }
      if (stackTrace != null) {
        final List<String> traceLines = stackTrace.toString().split('\n');
        final int maxLines = traceLines.length < 5 ? traceLines.length : 5;
        debugPrint(traceLines.take(maxLines).join('\n'));
      }
    }

    _invokeRemoteErrorReporter(
      message,
      error: error,
      stackTrace: stackTrace,
      attributes: attributes,
    );
  }

  void _invokeRemoteInfoReporter(String message) {
    final AppLoggerRemoteInfoReporter? reporter = _remoteInfoReporter;
    if (reporter == null) {
      return;
    }

    try {
      reporter(message);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('[LOGGER_REMOTE_INFO_ERROR] $error');
        debugPrint(stackTrace.toString());
      }
    }
  }

  void _invokeRemoteErrorReporter(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> attributes = const <String, Object?>{},
  }) {
    final AppLoggerRemoteErrorReporter? reporter = _remoteErrorReporter;
    if (reporter == null) {
      return;
    }

    try {
      reporter(
        message,
        error: error,
        stackTrace: stackTrace,
        attributes: attributes,
      );
    } catch (reportError, reportStackTrace) {
      if (kDebugMode) {
        debugPrint('[LOGGER_REMOTE_ERROR_ERROR] $reportError');
        debugPrint(reportStackTrace.toString());
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

import 'package:datadog_flutter_plugin/datadog_flutter_plugin.dart';
import 'package:flutter/material.dart';
import 'package:global_airsoft_app/src/core/config/app_config.dart';
import 'package:global_airsoft_app/src/core/logging/app_logger.dart';

final class AppTelemetry {
  AppTelemetry._();

  static final AppTelemetry instance = AppTelemetry._();

  bool _initialized = false;
  bool _enabled = false;
  DatadogLogger? _appLogger;

  Future<void> initialize(AppConfig config) async {
    if (_initialized) {
      return;
    }

    _initialized = true;
    _enabled = false;
    _appLogger = null;
    AppLogger.instance.setRemoteInfoReporter(null);
    AppLogger.instance.setRemoteErrorReporter(null);

    if (!config.datadogEnabled) {
      return;
    }

    if (config.datadogClientToken.isEmpty ||
        config.datadogRumApplicationId.isEmpty) {
      AppLogger.instance.info(
        'Datadog monitoring is disabled because credentials are missing.',
      );
      return;
    }

    try {
      DatadogSdk.instance.sdkVerbosity = config.enableDebugLogs
          ? CoreLoggerLevel.debug
          : CoreLoggerLevel.warn;

      final DatadogConfiguration datadogConfiguration = DatadogConfiguration(
        clientToken: config.datadogClientToken,
        env: config.environment.label,
        site: _parseSite(config.datadogSite),
        service: config.datadogServiceName,
        nativeCrashReportEnabled: true,
        loggingConfiguration: DatadogLoggingConfiguration(),
        rumConfiguration: DatadogRumConfiguration(
          applicationId: config.datadogRumApplicationId,
          detectLongTasks: true,
          reportFlutterPerformance: true,
        ),
      );

      await DatadogSdk.instance.initialize(
        datadogConfiguration,
        TrackingConsent.granted,
      );

      _appLogger = DatadogSdk.instance.logs?.createLogger(
        DatadogLoggerConfiguration(
          service: config.datadogServiceName,
          name: 'app-logs',
          remoteLogThreshold: LogLevel.info,
          customConsoleLogFunction: null,
        ),
      );

      AppLogger.instance.setRemoteInfoReporter(_reportAppLoggerInfo);
      AppLogger.instance.setRemoteErrorReporter(_reportAppLoggerError);
      _enabled = true;
    } catch (error, stackTrace) {
      AppLogger.instance.error(
        'Datadog monitoring failed to initialize',
        error: error,
        stackTrace: stackTrace,
      );
      _enabled = false;
      _appLogger = null;
      AppLogger.instance.setRemoteInfoReporter(null);
      AppLogger.instance.setRemoteErrorReporter(null);
    }
  }

  void _reportAppLoggerInfo(String message) {
    if (!_enabled) {
      return;
    }

    _appLogger?.info(message);
  }

  void _reportAppLoggerError(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_enabled) {
      return;
    }

    _appLogger?.error(
      message,
      errorMessage: error?.toString(),
      errorKind: error?.runtimeType.toString(),
      errorStackTrace: stackTrace,
    );
  }

  void reportFlutterError(FlutterErrorDetails details) {
    if (!_enabled) {
      return;
    }

    DatadogSdk.instance.rum?.handleFlutterError(details);
  }

  void reportPlatformError(Object error, StackTrace stackTrace) {
    if (!_enabled) {
      return;
    }

    DatadogSdk.instance.rum?.addErrorInfo(
      error.toString(),
      RumErrorSource.source,
      stackTrace: stackTrace,
    );
  }

  static DatadogSite _parseSite(String value) {
    switch (value.trim().toLowerCase()) {
      case 'us3':
        return DatadogSite.us3;
      case 'us1':
      default:
        return DatadogSite.us1;
    }
  }
}

enum AppEnvironment { test, dev, staging, prod }

extension AppEnvironmentX on AppEnvironment {
  String get label {
    switch (this) {
      case AppEnvironment.test:
        return 'test';
      case AppEnvironment.dev:
        return 'dev';
      case AppEnvironment.staging:
        return 'staging';
      case AppEnvironment.prod:
        return 'prod';
    }
  }
}

final class AppConfig {
  static const int _defaultTimeoutMs = 15000;
  static const int _minimumTimeoutMs = 1000;

  const AppConfig({
    required this.environment,
    required this.enableDebugLogs,
    required this.apiBaseUrl,
    required this.apiVersion,
    required this.connectTimeoutMs,
    required this.receiveTimeoutMs,
    required this.sendTimeoutMs,
    required this.datadogEnabled,
    required this.datadogClientToken,
    required this.datadogRumApplicationId,
    required this.datadogServiceName,
    required this.datadogSite,
  });

  final AppEnvironment environment;
  final bool enableDebugLogs;
  final String apiBaseUrl;
  final String apiVersion;
  final int connectTimeoutMs;
  final int receiveTimeoutMs;
  final int sendTimeoutMs;
  final bool datadogEnabled;
  final String datadogClientToken;
  final String datadogRumApplicationId;
  final String datadogServiceName;
  final String datadogSite;

  factory AppConfig.fromDartDefines() {
    final String envRaw = const String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'prod',
    ).trim().toLowerCase();

    final AppEnvironment environment;
    switch (envRaw) {
      case 'test':
        environment = AppEnvironment.test;
      case 'dev':
        environment = AppEnvironment.dev;
      case 'staging':
        environment = AppEnvironment.staging;
      case 'prod':
      default:
        environment = AppEnvironment.prod;
    }

    const String baseUrlFromDefines = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: '',
    );

    const int connectTimeoutFromDefines = int.fromEnvironment(
      'API_CONNECT_TIMEOUT_MS',
      defaultValue: _defaultTimeoutMs,
    );
    const int receiveTimeoutFromDefines = int.fromEnvironment(
      'API_RECEIVE_TIMEOUT_MS',
      defaultValue: _defaultTimeoutMs,
    );
    const int sendTimeoutFromDefines = int.fromEnvironment(
      'API_SEND_TIMEOUT_MS',
      defaultValue: _defaultTimeoutMs,
    );

    final String resolvedBaseUrl = _resolveBaseUrl(
      candidate: baseUrlFromDefines,
      fallback: _defaultBaseUrlFor(environment),
    );
    final String apiVersion = _normalizeApiVersion(
      const String.fromEnvironment('API_VERSION', defaultValue: 'v1'),
    );

    const String datadogClientToken = String.fromEnvironment(
      'DATADOG_CLIENT_TOKEN',
      defaultValue: '',
    );
    const String datadogRumApplicationId = String.fromEnvironment(
      'DATADOG_RUM_APPLICATION_ID',
      defaultValue: '',
    );
    const String datadogServiceName = String.fromEnvironment(
      'DATADOG_SERVICE_NAME',
      defaultValue: 'global_airsoft_app',
    );
    final String datadogSite = _normalizeDatadogSite(
      const String.fromEnvironment('DATADOG_SITE', defaultValue: 'us1'),
    );
    final bool datadogEnabled =
        const bool.fromEnvironment('DATADOG_ENABLED', defaultValue: false) ||
        environment == AppEnvironment.staging ||
        environment == AppEnvironment.prod;

    return AppConfig(
      environment: environment,
      enableDebugLogs: const bool.fromEnvironment(
        'APP_DEBUG_LOGS',
        defaultValue: false,
      ),
      apiBaseUrl: resolvedBaseUrl,
      apiVersion: apiVersion,
      connectTimeoutMs: _sanitizeTimeout(connectTimeoutFromDefines),
      receiveTimeoutMs: _sanitizeTimeout(receiveTimeoutFromDefines),
      sendTimeoutMs: _sanitizeTimeout(sendTimeoutFromDefines),
      datadogEnabled: datadogEnabled,
      datadogClientToken: datadogClientToken,
      datadogRumApplicationId: datadogRumApplicationId,
      datadogServiceName: datadogServiceName,
      datadogSite: datadogSite,
    );
  }

  static String _defaultBaseUrlFor(AppEnvironment environment) {
    switch (environment) {
      case AppEnvironment.test:
        return 'https://api-test.example.com';
      case AppEnvironment.dev:
        return 'https://api-dev.example.com';
      case AppEnvironment.staging:
        return 'https://api-staging.example.com';
      case AppEnvironment.prod:
        return 'https://api.example.com';
    }
  }

  static String _resolveBaseUrl({
    required String candidate,
    required String fallback,
  }) {
    final String normalizedCandidate = _normalizeBaseUrl(candidate);
    if (normalizedCandidate.isEmpty) {
      return _normalizeBaseUrl(fallback);
    }

    final Uri? parsed = Uri.tryParse(normalizedCandidate);
    if (parsed == null ||
        parsed.host.isEmpty ||
        (parsed.scheme != 'http' && parsed.scheme != 'https')) {
      return _normalizeBaseUrl(fallback);
    }

    return normalizedCandidate;
  }

  static String _normalizeBaseUrl(String value) {
    return value.trim().replaceFirst(RegExp(r'/+$'), '');
  }

  static String _normalizeApiVersion(String value) {
    final String normalized = value.trim().toLowerCase().replaceAll(
      RegExp(r'^/+|/+$'),
      '',
    );
    if (normalized.isEmpty) {
      return 'v1';
    }

    return normalized;
  }

  static String _normalizeDatadogSite(String value) {
    final String normalized = value.trim().toLowerCase();
    switch (normalized) {
      case 'us3':
        return 'us3';
      case 'us1':
      default:
        return 'us1';
    }
  }

  static int _sanitizeTimeout(int value) {
    if (value < _minimumTimeoutMs) {
      return _defaultTimeoutMs;
    }
    return value;
  }
}

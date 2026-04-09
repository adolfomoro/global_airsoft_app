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
    required this.connectTimeoutMs,
    required this.receiveTimeoutMs,
    required this.sendTimeoutMs,
  });

  final AppEnvironment environment;
  final bool enableDebugLogs;
  final String apiBaseUrl;
  final int connectTimeoutMs;
  final int receiveTimeoutMs;
  final int sendTimeoutMs;

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

    return AppConfig(
      environment: environment,
      enableDebugLogs: const bool.fromEnvironment(
        'APP_DEBUG_LOGS',
        defaultValue: false,
      ),
      apiBaseUrl: resolvedBaseUrl,
      connectTimeoutMs: _sanitizeTimeout(connectTimeoutFromDefines),
      receiveTimeoutMs: _sanitizeTimeout(receiveTimeoutFromDefines),
      sendTimeoutMs: _sanitizeTimeout(sendTimeoutFromDefines),
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

  static int _sanitizeTimeout(int value) {
    if (value < _minimumTimeoutMs) {
      return _defaultTimeoutMs;
    }
    return value;
  }
}

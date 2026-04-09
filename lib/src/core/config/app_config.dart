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
      defaultValue: 15000,
    );
    const int receiveTimeoutFromDefines = int.fromEnvironment(
      'API_RECEIVE_TIMEOUT_MS',
      defaultValue: 15000,
    );
    const int sendTimeoutFromDefines = int.fromEnvironment(
      'API_SEND_TIMEOUT_MS',
      defaultValue: 15000,
    );

    return AppConfig(
      environment: environment,
      enableDebugLogs: const bool.fromEnvironment(
        'APP_DEBUG_LOGS',
        defaultValue: false,
      ),
      apiBaseUrl: baseUrlFromDefines.trim().isNotEmpty
          ? baseUrlFromDefines.trim()
          : _defaultBaseUrlFor(environment),
      connectTimeoutMs: connectTimeoutFromDefines,
      receiveTimeoutMs: receiveTimeoutFromDefines,
      sendTimeoutMs: sendTimeoutFromDefines,
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
}

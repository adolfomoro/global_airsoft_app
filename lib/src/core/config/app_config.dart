enum AppEnvironment { dev, staging, prod }

extension AppEnvironmentX on AppEnvironment {
  String get label {
    switch (this) {
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
  const AppConfig({required this.environment, required this.enableDebugLogs});

  final AppEnvironment environment;
  final bool enableDebugLogs;

  factory AppConfig.fromDartDefines() {
    final String envRaw = const String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'prod',
    ).trim().toLowerCase();

    final AppEnvironment environment;
    switch (envRaw) {
      case 'dev':
        environment = AppEnvironment.dev;
      case 'staging':
        environment = AppEnvironment.staging;
      case 'prod':
      default:
        environment = AppEnvironment.prod;
    }

    return AppConfig(
      environment: environment,
      enableDebugLogs: const bool.fromEnvironment(
        'APP_DEBUG_LOGS',
        defaultValue: false,
      ),
    );
  }
}

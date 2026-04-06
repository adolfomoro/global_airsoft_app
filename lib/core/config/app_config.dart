class AppConfig {
  const AppConfig({
    required this.appEnv,
    required this.apiBaseUrl,
    required this.apiVersion,
    required this.connectTimeoutMs,
    required this.receiveTimeoutMs,
    required this.sendTimeoutMs,
    required this.deviceSyncRetryMs,
    required this.enableNetworkLogs,
  });

  static const AppConfig current = AppConfig(
    appEnv: String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'production',
    ),
    apiBaseUrl: String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://api.global-airsoft.com',
    ),
    apiVersion: String.fromEnvironment(
      'API_VERSION',
      defaultValue: '1.0.0-alpha',
    ),
    connectTimeoutMs: int.fromEnvironment(
      'API_CONNECT_TIMEOUT_MS',
      defaultValue: 10000,
    ),
    receiveTimeoutMs: int.fromEnvironment(
      'API_RECEIVE_TIMEOUT_MS',
      defaultValue: 10000,
    ),
    sendTimeoutMs: int.fromEnvironment(
      'API_SEND_TIMEOUT_MS',
      defaultValue: 10000,
    ),
    deviceSyncRetryMs: int.fromEnvironment(
      'DEVICE_SYNC_RETRY_MS',
      defaultValue: 8000,
    ),
    enableNetworkLogs: bool.fromEnvironment(
      'ENABLE_NETWORK_LOGS',
      defaultValue: false,
    ),
  );

  final String appEnv;
  final String apiBaseUrl;
  final String apiVersion;
  final int connectTimeoutMs;
  final int receiveTimeoutMs;
  final int sendTimeoutMs;
  final int deviceSyncRetryMs;
  final bool enableNetworkLogs;

  String get normalizedApiBaseUrl {
    final trimmed = apiBaseUrl.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  String get normalizedApiVersion {
    final trimmed = apiVersion.trim();
    if (trimmed.isEmpty) {
      return '1.0.0';
    }
    return trimmed.replaceAll('/', '');
  }

  String get apiPrefix => '/$normalizedApiVersion';

  bool get isProduction => appEnv.toLowerCase() == 'production';

  Duration get connectTimeout => Duration(milliseconds: connectTimeoutMs);
  Duration get receiveTimeout => Duration(milliseconds: receiveTimeoutMs);
  Duration get sendTimeout => Duration(milliseconds: sendTimeoutMs);
  Duration get deviceSyncRetry => Duration(milliseconds: deviceSyncRetryMs);
}
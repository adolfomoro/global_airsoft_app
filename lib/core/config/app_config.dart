class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.connectTimeoutMs,
    required this.receiveTimeoutMs,
    required this.sendTimeoutMs,
  });

  static const AppConfig current = AppConfig(
    apiBaseUrl: String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://api.global-airsoft.com',
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
  );

  final String apiBaseUrl;
  final int connectTimeoutMs;
  final int receiveTimeoutMs;
  final int sendTimeoutMs;

  String get normalizedApiBaseUrl {
    final trimmed = apiBaseUrl.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  Duration get connectTimeout => Duration(milliseconds: connectTimeoutMs);
  Duration get receiveTimeout => Duration(milliseconds: receiveTimeoutMs);
  Duration get sendTimeout => Duration(milliseconds: sendTimeoutMs);
}
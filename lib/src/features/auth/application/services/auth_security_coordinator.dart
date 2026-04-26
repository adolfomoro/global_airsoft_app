import 'package:global_airsoft_app/src/features/auth/domain/models/auth_tokens.dart';

typedef AuthTokensReader = Future<AuthTokens?> Function();
typedef AuthTokensWriter = Future<void> Function(AuthTokens tokens);
typedef AuthSessionClearer = Future<void> Function();
typedef AuthTokensRefresher = Future<AuthTokens> Function(String refreshToken);
typedef AuthMessageTranslator = Future<String> Function(String key);
typedef AuthMessagePresenter = Future<void> Function(String message);

final class AuthSecurityCoordinator {
  AuthSecurityCoordinator._();

  static final AuthSecurityCoordinator instance = AuthSecurityCoordinator._();

  AuthTokensReader? _getTokens;
  AuthTokensWriter? _saveTokens;
  AuthSessionClearer? _clearSession;
  AuthTokensRefresher? _refreshTokens;
  AuthMessageTranslator? _translateMessage;
  AuthMessagePresenter? _showMessage;
  AuthTokens? _cachedTokens;
  bool _hasCachedTokens = false;
  int _cachedTokensRevision = 0;
  Future<AuthTokens?>? _tokensLoadInFlight;
  final Map<String, DateTime> _recentMessages = <String, DateTime>{};
  Duration _duplicateMessageWindow = const Duration(seconds: 12);
  int _sessionVersion = 0;

  bool get isConfigured {
    return _getTokens != null &&
        _saveTokens != null &&
        _clearSession != null &&
        _refreshTokens != null &&
        _translateMessage != null &&
        _showMessage != null;
  }

  int get sessionVersion => _sessionVersion;

  bool get hasCachedTokens => _hasCachedTokens;

  AuthTokens? get cachedTokens => _cachedTokens;

  void configure({
    required AuthTokensReader getTokens,
    required AuthTokensWriter saveTokens,
    required AuthSessionClearer clearSession,
    required AuthTokensRefresher refreshTokens,
    required AuthMessageTranslator translateMessage,
    required AuthMessagePresenter showMessage,
    AuthTokens? initialTokens,
    bool cacheInitialTokens = false,
    Duration duplicateMessageWindow = const Duration(seconds: 12),
  }) {
    _getTokens = getTokens;
    _saveTokens = saveTokens;
    _clearSession = clearSession;
    _refreshTokens = refreshTokens;
    _translateMessage = translateMessage;
    _showMessage = showMessage;
    if (cacheInitialTokens) {
      cacheTokens(initialTokens);
    } else {
      _resetCachedTokens();
    }
    _duplicateMessageWindow = duplicateMessageWindow;
    _recentMessages.clear();
    _sessionVersion = 0;
  }

  void reset() {
    _getTokens = null;
    _saveTokens = null;
    _clearSession = null;
    _refreshTokens = null;
    _translateMessage = null;
    _showMessage = null;
    _resetCachedTokens();
    _recentMessages.clear();
    _duplicateMessageWindow = const Duration(seconds: 12);
    _sessionVersion = 0;
  }

  void notifySessionChanged() {
    _sessionVersion += 1;
  }

  Future<AuthTokens?> readTokens() async {
    if (_hasCachedTokens) {
      return _cachedTokens;
    }

    final AuthTokensReader? reader = _getTokens;
    if (reader == null) {
      return null;
    }

    final Future<AuthTokens?>? ongoing = _tokensLoadInFlight;
    if (ongoing != null) {
      return ongoing;
    }

    final int cacheRevisionAtStart = _cachedTokensRevision;
    final Future<AuthTokens?> loadFuture = _loadTokens(
      reader: reader,
      cacheRevisionAtStart: cacheRevisionAtStart,
    );
    _tokensLoadInFlight = loadFuture;

    try {
      return await loadFuture;
    } finally {
      if (identical(_tokensLoadInFlight, loadFuture)) {
        _tokensLoadInFlight = null;
      }
    }
  }

  Future<void> saveTokens(AuthTokens tokens) async {
    final AuthTokensWriter? writer = _saveTokens;
    if (writer == null) {
      cacheTokens(tokens);
      return;
    }

    await writer(tokens);
    cacheTokens(tokens);
  }

  Future<void> clearSession() async {
    notifySessionChanged();
    cacheTokens(null);

    final AuthSessionClearer? clearer = _clearSession;
    if (clearer == null) {
      return;
    }

    await clearer();
  }

  Future<AuthTokens> refreshTokens(String refreshToken) async {
    final AuthTokensRefresher? refresher = _refreshTokens;
    if (refresher == null) {
      throw StateError('Auth security coordinator is not configured.');
    }

    return refresher(refreshToken);
  }

  Future<String> translateMessage(String key) async {
    final AuthMessageTranslator? translator = _translateMessage;
    if (translator == null) {
      return '';
    }

    return (await translator(key)).trim();
  }

  Future<void> showMessage(String message) async {
    final String normalizedMessage = message.trim();
    if (normalizedMessage.isEmpty) {
      return;
    }

    _pruneExpiredMessages();

    final DateTime now = DateTime.now();
    final DateTime? lastShownAt = _recentMessages[normalizedMessage];
    if (lastShownAt != null &&
        now.difference(lastShownAt) < _duplicateMessageWindow) {
      return;
    }

    _recentMessages[normalizedMessage] = now;

    final AuthMessagePresenter? presenter = _showMessage;
    if (presenter == null) {
      return;
    }

    await presenter(normalizedMessage);
  }

  void _pruneExpiredMessages() {
    if (_recentMessages.isEmpty) {
      return;
    }

    final DateTime now = DateTime.now();
    _recentMessages.removeWhere((String message, DateTime shownAt) {
      return now.difference(shownAt) >= _duplicateMessageWindow;
    });
  }

  void cacheTokens(AuthTokens? tokens) {
    _cachedTokens = tokens;
    _hasCachedTokens = true;
    _cachedTokensRevision += 1;
  }

  void _resetCachedTokens() {
    _cachedTokens = null;
    _hasCachedTokens = false;
    _cachedTokensRevision += 1;
    _tokensLoadInFlight = null;
  }

  Future<AuthTokens?> _loadTokens({
    required AuthTokensReader reader,
    required int cacheRevisionAtStart,
  }) async {
    final AuthTokens? loadedTokens = await reader();
    if (!_hasCachedTokens && cacheRevisionAtStart == _cachedTokensRevision) {
      cacheTokens(loadedTokens);
    }

    return _cachedTokens;
  }
}

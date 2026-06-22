typedef CurrentTimeProvider = DateTime Function();

final class CurrentUserProfileReloadThrottle {
  CurrentUserProfileReloadThrottle({
    required Duration minInterval,
    CurrentTimeProvider? currentTimeProvider,
  }) : _minInterval = minInterval,
       _currentTimeProvider = currentTimeProvider ?? DateTime.now;

  final Duration _minInterval;
  final CurrentTimeProvider _currentTimeProvider;
  DateTime? _lastSuccessfulReloadAt;

  bool shouldThrottleReload() {
    if (_minInterval <= Duration.zero) {
      return false;
    }

    final DateTime? lastSuccessfulReloadAt = _lastSuccessfulReloadAt;
    if (lastSuccessfulReloadAt == null) {
      return false;
    }

    final Duration elapsed =
        _currentTimeProvider().difference(lastSuccessfulReloadAt);
    return elapsed < _minInterval;
  }

  void markSuccessfulReload() {
    _lastSuccessfulReloadAt = _currentTimeProvider();
  }

  void reset() {
    _lastSuccessfulReloadAt = null;
  }
}

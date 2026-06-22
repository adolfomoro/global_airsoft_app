import 'package:flutter_test/flutter_test.dart';
import 'package:global_airsoft_app/src/features/users/application/services/current_user_profile_reload_throttle.dart';

void main() {
  test('does not throttle before first successful reload', () {
    final CurrentUserProfileReloadThrottle throttle =
        CurrentUserProfileReloadThrottle(minInterval: const Duration(seconds: 10));

    expect(throttle.shouldThrottleReload(), isFalse);
  });

  test('throttles reloads inside the configured interval', () {
    DateTime now = DateTime(2026, 1, 1, 12, 0, 0);
    final CurrentUserProfileReloadThrottle throttle =
        CurrentUserProfileReloadThrottle(
          minInterval: const Duration(seconds: 10),
          currentTimeProvider: () => now,
        );

    throttle.markSuccessfulReload();
    now = now.add(const Duration(seconds: 3));

    expect(throttle.shouldThrottleReload(), isTrue);
  });

  test('allows reloads again after interval elapses', () {
    DateTime now = DateTime(2026, 1, 1, 12, 0, 0);
    final CurrentUserProfileReloadThrottle throttle =
        CurrentUserProfileReloadThrottle(
          minInterval: const Duration(seconds: 10),
          currentTimeProvider: () => now,
        );

    throttle.markSuccessfulReload();
    now = now.add(const Duration(seconds: 11));

    expect(throttle.shouldThrottleReload(), isFalse);
  });

  test('reset clears throttle state', () {
    DateTime now = DateTime(2026, 1, 1, 12, 0, 0);
    final CurrentUserProfileReloadThrottle throttle =
        CurrentUserProfileReloadThrottle(
          minInterval: const Duration(seconds: 10),
          currentTimeProvider: () => now,
        );

    throttle.markSuccessfulReload();
    now = now.add(const Duration(seconds: 3));
    expect(throttle.shouldThrottleReload(), isTrue);

    throttle.reset();
    expect(throttle.shouldThrottleReload(), isFalse);
  });
}

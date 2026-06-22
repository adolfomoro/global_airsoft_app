import 'package:flutter_test/flutter_test.dart';
import 'package:global_airsoft_app/src/app/startup/app_startup_metrics.dart';
import 'package:global_airsoft_app/src/app/startup/app_startup_orchestrator.dart';

void main() {
  group('AppBootstrapState metrics', () {
    test('returns null metrics when critical timing incomplete', () {
      const state = AppBootstrapState();

      expect(state.metrics, isNull);
    });

    test('calculates metrics when critical timing complete', () {
      final now = DateTime.now().toUtc();
      final start = now;
      final end = now.add(Duration(milliseconds: 2000));

      final state = AppBootstrapState(
        phase: AppBootstrapPhase.criticalReady,
        criticalStartedAt: start,
        criticalCompletedAt: end,
      );

      final metrics = state.metrics;
      expect(metrics, isNotNull);
      expect(metrics!.criticalDurationMs, 2000);
      expect(metrics.backgroundPhaseTiming, isNull);
    });

    test('includes background timing when available', () {
      final now = DateTime.now().toUtc();
      final criticalStart = now;
      final criticalEnd = now.add(Duration(milliseconds: 1500));
      final bgStart = criticalEnd;
      final bgEnd = bgStart.add(Duration(milliseconds: 2500));

      final state = AppBootstrapState(
        phase: AppBootstrapPhase.ready,
        criticalStartedAt: criticalStart,
        criticalCompletedAt: criticalEnd,
        backgroundStartedAt: bgStart,
        backgroundCompletedAt: bgEnd,
      );

      final metrics = state.metrics;
      expect(metrics, isNotNull);
      expect(metrics!.criticalDurationMs, 1500);
      expect(metrics.backgroundDurationMs, 2500);
      expect(metrics.totalStartupTimeMs, 1500);
    });

    test('checkCriticalHealth returns null without metrics', () {
      const state = AppBootstrapState();

      expect(state.checkCriticalHealth(), isNull);
    });

    test('checkCriticalHealth validates timing', () {
      final now = DateTime.now().toUtc();
      final state = AppBootstrapState(
        phase: AppBootstrapPhase.criticalReady,
        criticalStartedAt: now,
        criticalCompletedAt: now.add(Duration(milliseconds: 1500)),
      );

      final check = state.checkCriticalHealth(budgetMs: 2000);
      expect(check, isNotNull);
      expect(check!.status, AppBootstrapHealthStatus.healthy);
      expect(check.actualDurationMs, 1500);
      expect(check.budgetMs, 2000);
    });

    test('checkCriticalHealth detects degradation', () {
      final now = DateTime.now().toUtc();
      final state = AppBootstrapState(
        phase: AppBootstrapPhase.criticalReady,
        criticalStartedAt: now,
        criticalCompletedAt: now.add(Duration(milliseconds: 4500)),
      );

      final check = state.checkCriticalHealth(budgetMs: 3000);
      expect(check, isNotNull);
      expect(check!.status, AppBootstrapHealthStatus.degraded);
    });

    test('checkCriticalHealth detects unhealthy', () {
      final now = DateTime.now().toUtc();
      final state = AppBootstrapState(
        phase: AppBootstrapPhase.criticalReady,
        criticalStartedAt: now,
        criticalCompletedAt: now.add(Duration(milliseconds: 6500)),
      );

      final check = state.checkCriticalHealth(budgetMs: 3000);
      expect(check, isNotNull);
      expect(check!.status, AppBootstrapHealthStatus.unhealthy);
    });

    test('checkBackgroundHealth returns null without background timing', () {
      final now = DateTime.now().toUtc();
      final state = AppBootstrapState(
        phase: AppBootstrapPhase.criticalReady,
        criticalStartedAt: now,
        criticalCompletedAt: now.add(Duration(milliseconds: 1000)),
      );

      expect(state.checkBackgroundHealth(), isNull);
    });

    test('checkBackgroundHealth validates background timing', () {
      final now = DateTime.now().toUtc();
      final bgStart = now.add(Duration(milliseconds: 1000));
      final bgEnd = bgStart.add(Duration(milliseconds: 3000));

      final state = AppBootstrapState(
        phase: AppBootstrapPhase.ready,
        criticalStartedAt: now,
        criticalCompletedAt: now.add(Duration(milliseconds: 1000)),
        backgroundStartedAt: bgStart,
        backgroundCompletedAt: bgEnd,
      );

      final check = state.checkBackgroundHealth(budgetMs: 4000);
      expect(check, isNotNull);
      expect(check!.status, AppBootstrapHealthStatus.healthy);
      expect(check.actualDurationMs, 3000);
    });

    test('overallHealth reflects critical phase health', () {
      final now = DateTime.now().toUtc();
      final state = AppBootstrapState(
        phase: AppBootstrapPhase.criticalReady,
        criticalStartedAt: now,
        criticalCompletedAt: now.add(Duration(milliseconds: 2000)),
      );

      expect(state.overallHealth, AppBootstrapHealthStatus.healthy);
    });

    test('overallHealth reflects degradation in critical path', () {
      final now = DateTime.now().toUtc();
      final state = AppBootstrapState(
        phase: AppBootstrapPhase.criticalReady,
        criticalStartedAt: now,
        criticalCompletedAt: now.add(Duration(milliseconds: 4000)),
      );

      expect(state.overallHealth, AppBootstrapHealthStatus.degraded);
    });

    test('copyWith preserves timing data', () {
      final now = DateTime.now().toUtc();
      final original = AppBootstrapState(
        phase: AppBootstrapPhase.criticalReady,
        criticalStartedAt: now,
        criticalCompletedAt: now.add(Duration(milliseconds: 1000)),
      );

      final updated = original.copyWith(
        phase: AppBootstrapPhase.backgroundInitializing,
      );

      expect(updated.criticalStartedAt, original.criticalStartedAt);
      expect(updated.criticalCompletedAt, original.criticalCompletedAt);
      expect(updated.phase, AppBootstrapPhase.backgroundInitializing);
    });
  });
}

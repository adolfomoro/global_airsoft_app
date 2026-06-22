import 'package:flutter_test/flutter_test.dart';
import 'package:global_airsoft_app/src/app/startup/app_startup_metrics.dart';

void main() {
  group('AppBootstrapPhaseTiming', () {
    test('calculates duration correctly', () {
      final start = DateTime(2024, 1, 1, 12, 0, 0);
      final end = DateTime(2024, 1, 1, 12, 0, 2, 500); // 2.5 seconds

      final timing = AppBootstrapPhaseTiming(
        phaseName: 'test',
        startedAt: start,
        completedAt: end,
      );

      expect(timing.durationMs, 2500);
      expect(timing.duration.inMilliseconds, 2500);
    });

    test('toString formats correctly', () {
      final start = DateTime(2024, 1, 1, 12, 0, 0);
      final end = DateTime(2024, 1, 1, 12, 0, 1);

      final timing = AppBootstrapPhaseTiming(
        phaseName: 'critical',
        startedAt: start,
        completedAt: end,
      );

      expect(timing.toString(), contains('critical'));
      expect(timing.toString(), contains('1000ms'));
    });
  });

  group('AppBootstrapHealthCheck', () {
    test('marks healthy when within budget', () {
      final check = AppBootstrapHealthCheck(
        phaseName: 'test',
        actualDurationMs: 1000,
        budgetMs: 2000,
        status: AppBootstrapHealthStatus.healthy,
      );

      expect(check.status, AppBootstrapHealthStatus.healthy);
      expect(check.percentageUsed, 50.0);
      expect(check.remainingBudgetMs, 1000);
    });

    test('marks degraded when 100-150% of budget', () {
      final check = AppBootstrapHealthCheck(
        phaseName: 'test',
        actualDurationMs: 1300,
        budgetMs: 1000,
        status: AppBootstrapHealthStatus.degraded,
      );

      expect(check.status, AppBootstrapHealthStatus.degraded);
      expect(check.percentageUsed, 130.0);
      expect(check.remainingBudgetMs, 0); // Clamped to 0
    });

    test('marks unhealthy when exceeds 150% of budget', () {
      final check = AppBootstrapHealthCheck(
        phaseName: 'test',
        actualDurationMs: 2000,
        budgetMs: 1000,
        status: AppBootstrapHealthStatus.unhealthy,
      );

      expect(check.status, AppBootstrapHealthStatus.unhealthy);
      expect(check.percentageUsed, 200.0);
    });

    test('toString includes all relevant info', () {
      final check = AppBootstrapHealthCheck(
        phaseName: 'critical',
        actualDurationMs: 1500,
        budgetMs: 2000,
        status: AppBootstrapHealthStatus.healthy,
      );

      final str = check.toString();
      expect(str, contains('critical'));
      expect(str, contains('1500ms'));
      expect(str, contains('2000ms'));
      expect(str, contains('75.0%'));
      expect(str, contains('healthy'));
    });
  });

  group('AppStartupMetrics', () {
    test('creates metrics from timing data', () {
      final now = DateTime.now().toUtc();
      final criticalStart = now;
      final criticalEnd = now.add(Duration(milliseconds: 2500));

      final criticalTiming = AppBootstrapPhaseTiming(
        phaseName: 'critical',
        startedAt: criticalStart,
        completedAt: criticalEnd,
      );

      final metrics = AppStartupMetrics(
        criticalPhaseTiming: criticalTiming,
        totalStartupTime: Duration(milliseconds: 2500),
      );

      expect(metrics.criticalDurationMs, 2500);
      expect(metrics.totalStartupTimeMs, 2500);
      expect(metrics.backgroundDurationMs, isNull);
    });

    test('includes background timing when available', () {
      final now = DateTime.now().toUtc();
      final criticalStart = now;
      final criticalEnd = now.add(Duration(milliseconds: 2000));
      final bgStart = criticalEnd;
      final bgEnd = bgStart.add(Duration(milliseconds: 3000));

      final criticalTiming = AppBootstrapPhaseTiming(
        phaseName: 'critical',
        startedAt: criticalStart,
        completedAt: criticalEnd,
      );

      final bgTiming = AppBootstrapPhaseTiming(
        phaseName: 'background',
        startedAt: bgStart,
        completedAt: bgEnd,
      );

      final metrics = AppStartupMetrics(
        criticalPhaseTiming: criticalTiming,
        backgroundPhaseTiming: bgTiming,
        totalStartupTime: Duration(milliseconds: 2000),
      );

      expect(metrics.criticalDurationMs, 2000);
      expect(metrics.backgroundDurationMs, 3000);
      expect(metrics.totalStartupTimeMs, 2000);
    });

    test('checkCriticalPhaseHealth uses default budget', () {
      final now = DateTime.now().toUtc();
      final criticalTiming = AppBootstrapPhaseTiming(
        phaseName: 'critical',
        startedAt: now,
        completedAt: now.add(Duration(milliseconds: 2000)),
      );

      final metrics = AppStartupMetrics(
        criticalPhaseTiming: criticalTiming,
        totalStartupTime: Duration(milliseconds: 2000),
      );

      final check = metrics.checkCriticalPhaseHealth();
      expect(check, isNotNull);
      expect(check.status, AppBootstrapHealthStatus.healthy);
      expect(check.budgetMs, 3000); // Default
    });

    test('checkCriticalPhaseHealth respects custom budget', () {
      final now = DateTime.now().toUtc();
      final criticalTiming = AppBootstrapPhaseTiming(
        phaseName: 'critical',
        startedAt: now,
        completedAt: now.add(Duration(milliseconds: 2000)),
      );

      final metrics = AppStartupMetrics(
        criticalPhaseTiming: criticalTiming,
        totalStartupTime: Duration(milliseconds: 2000),
      );

      final check = metrics.checkCriticalPhaseHealth(budgetMs: 1000);
      expect(check, isNotNull);
  expect(check.status, AppBootstrapHealthStatus.unhealthy); // 200% of budget
      expect(check.budgetMs, 1000);
    });

    test('checkBackgroundPhaseHealth returns null without background timing', () {
      final now = DateTime.now().toUtc();
      final criticalTiming = AppBootstrapPhaseTiming(
        phaseName: 'critical',
        startedAt: now,
        completedAt: now.add(Duration(milliseconds: 1000)),
      );

      final metrics = AppStartupMetrics(
        criticalPhaseTiming: criticalTiming,
        totalStartupTime: Duration(milliseconds: 1000),
      );

      expect(metrics.checkBackgroundPhaseHealth(), isNull);
    });

    test('summary includes all timing data', () {
      final now = DateTime.now().toUtc();
      final criticalTiming = AppBootstrapPhaseTiming(
        phaseName: 'critical',
        startedAt: now,
        completedAt: now.add(Duration(milliseconds: 2000)),
      );

      final metrics = AppStartupMetrics(
        criticalPhaseTiming: criticalTiming,
        totalStartupTime: Duration(milliseconds: 2000),
      );

      final summary = metrics.summary;
      expect(summary, contains('Startup Metrics'));
      expect(summary, contains('critical'));
      expect(summary, contains('2000ms'));
    });
  });

  group('AppBootstrapHealthStatus determination', () {
    test('checkCriticalPhaseHealth marks healthy when within budget', () {
      final now = DateTime.now().toUtc();
      final criticalTiming = AppBootstrapPhaseTiming(
        phaseName: 'critical',
        startedAt: now,
        completedAt: now.add(Duration(milliseconds: 1000)),
      );

      final metrics = AppStartupMetrics(
        criticalPhaseTiming: criticalTiming,
        totalStartupTime: Duration(milliseconds: 1000),
      );

      final check = metrics.checkCriticalPhaseHealth(budgetMs: 1000);
  expect(check.status, AppBootstrapHealthStatus.healthy);
    });

    test('checkCriticalPhaseHealth marks degraded when 100-150% over budget', () {
      final now = DateTime.now().toUtc();
      final criticalTiming = AppBootstrapPhaseTiming(
        phaseName: 'critical',
        startedAt: now,
        completedAt: now.add(Duration(milliseconds: 1300)),
      );

      final metrics = AppStartupMetrics(
        criticalPhaseTiming: criticalTiming,
        totalStartupTime: Duration(milliseconds: 1300),
      );

      final check = metrics.checkCriticalPhaseHealth(budgetMs: 1000);
  expect(check.status, AppBootstrapHealthStatus.degraded);
    });

    test('checkCriticalPhaseHealth marks unhealthy when > 150% over budget', () {
      final now = DateTime.now().toUtc();
      final criticalTiming = AppBootstrapPhaseTiming(
        phaseName: 'critical',
        startedAt: now,
        completedAt: now.add(Duration(milliseconds: 1600)),
      );

      final metrics = AppStartupMetrics(
        criticalPhaseTiming: criticalTiming,
        totalStartupTime: Duration(milliseconds: 1600),
      );

      final check = metrics.checkCriticalPhaseHealth(budgetMs: 1000);
      expect(check.status, AppBootstrapHealthStatus.unhealthy);
    });
  });
}

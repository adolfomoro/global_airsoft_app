/// Represents timing metrics for a single startup phase.
final class AppBootstrapPhaseTiming {
  const AppBootstrapPhaseTiming({
    required this.phaseName,
    required this.startedAt,
    required this.completedAt,
  });

  /// The name of the phase being timed.
  final String phaseName;

  /// When the phase started.
  final DateTime startedAt;

  /// When the phase completed.
  final DateTime completedAt;

  /// Duration of the phase.
  Duration get duration => completedAt.difference(startedAt);

  /// Duration in milliseconds.
  int get durationMs => duration.inMilliseconds;

  @override
  String toString() =>
      '$phaseName: ${durationMs}ms (${startedAt.toIso8601String()} → ${completedAt.toIso8601String()})';
}

/// Health check status for startup phases.
enum AppBootstrapHealthStatus {
  /// Phase completed within acceptable time budget.
  healthy,

  /// Phase completed but exceeded warning threshold.
  degraded,

  /// Phase exceeded critical time budget.
  unhealthy,
}

/// Represents a health check result for a startup phase.
final class AppBootstrapHealthCheck {
  const AppBootstrapHealthCheck({
    required this.phaseName,
    required this.actualDurationMs,
    required this.budgetMs,
    required this.status,
  });

  /// The name of the phase being checked.
  final String phaseName;

  /// Actual duration in milliseconds.
  final int actualDurationMs;

  /// Budget/threshold in milliseconds.
  final int budgetMs;

  /// Health status.
  final AppBootstrapHealthStatus status;

  /// Percentage of budget used.
  double get percentageUsed => (actualDurationMs / budgetMs) * 100;

  /// Remaining budget in milliseconds.
  int get remainingBudgetMs => (budgetMs - actualDurationMs).clamp(0, budgetMs);

  @override
  String toString() =>
      '$phaseName: ${actualDurationMs}ms / ${budgetMs}ms (${percentageUsed.toStringAsFixed(1)}%, status: $status)';
}

/// Comprehensive startup performance metrics.
final class AppStartupMetrics {
  const AppStartupMetrics({
    required this.criticalPhaseTiming,
    this.backgroundPhaseTiming,
    this.totalStartupTime,
  });

  /// Timing data for the critical startup phase.
  final AppBootstrapPhaseTiming criticalPhaseTiming;

  /// Timing data for the background startup phase (if completed).
  final AppBootstrapPhaseTiming? backgroundPhaseTiming;

  /// Total time from startup start to readiness (critical only).
  final Duration? totalStartupTime;

  /// Critical phase duration in milliseconds.
  int get criticalDurationMs => criticalPhaseTiming.durationMs;

  /// Background phase duration in milliseconds (if available).
  int? get backgroundDurationMs => backgroundPhaseTiming?.durationMs;

  /// Total startup time in milliseconds (critical path only).
  int? get totalStartupTimeMs => totalStartupTime?.inMilliseconds;

  /// Returns health check for critical phase with given budget.
  AppBootstrapHealthCheck checkCriticalPhaseHealth({
    int budgetMs = 3000, // Default: 3 seconds for critical path
  }) {
    final status = _determineHealth(criticalDurationMs, budgetMs);
    return AppBootstrapHealthCheck(
      phaseName: 'critical',
      actualDurationMs: criticalDurationMs,
      budgetMs: budgetMs,
      status: status,
    );
  }

  /// Returns health check for background phase with given budget.
  AppBootstrapHealthCheck? checkBackgroundPhaseHealth({
    int budgetMs = 5000, // Default: 5 seconds for background
  }) {
    final bgDuration = backgroundDurationMs;
    if (bgDuration == null) return null;

    final status = _determineHealth(bgDuration, budgetMs);
    return AppBootstrapHealthCheck(
      phaseName: 'background',
      actualDurationMs: bgDuration,
      budgetMs: budgetMs,
      status: status,
    );
  }

  /// Determines health status based on actual vs budget duration.
  static AppBootstrapHealthStatus _determineHealth(
    int actualMs,
    int budgetMs,
  ) {
    final percentage = (actualMs / budgetMs) * 100;

    if (percentage <= 100) {
      return AppBootstrapHealthStatus.healthy;
    } else if (percentage <= 150) {
      return AppBootstrapHealthStatus.degraded;
    } else {
      return AppBootstrapHealthStatus.unhealthy;
    }
  }

  /// Summary string for logging.
  String get summary {
    final sb = StringBuffer();
    sb.writeln('=== Startup Metrics ===');
    sb.writeln(criticalPhaseTiming);
    if (backgroundPhaseTiming != null) {
      sb.writeln(backgroundPhaseTiming);
    }
    if (totalStartupTime != null) {
      sb.writeln('Total Startup: ${totalStartupTime!.inMilliseconds}ms');
    }
    sb.write('================');
    return sb.toString();
  }

  @override
  String toString() => summary;
}

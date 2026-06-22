import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/app/app_providers.dart';
import 'package:global_airsoft_app/src/app/services/app_startup_service.dart';
import 'package:global_airsoft_app/src/app/startup/app_startup_metrics.dart';
import 'package:global_airsoft_app/src/core/logging/app_logger.dart';

final Provider<AppStartupServiceContract> appStartupServiceProvider =
    Provider<AppStartupServiceContract>((Ref ref) {
      final appStartupService = AppStartupService(
        deviceRegistrationService: ref.watch(deviceRegistrationServiceProvider),
        pushNotificationService: ref.watch(pushNotificationServiceProvider),
        onPushTokenReceived: (String token) {
          ref.read(pushTokenProvider.notifier).setToken(token);
        },
        logger: AppLogger.instance,
      );

      return appStartupService;
    });

enum AppBootstrapPhase {
  initial,
  criticalInitializing,
  criticalReady,
  backgroundInitializing,
  ready,
  degraded,
}

final class AppBootstrapState {
  const AppBootstrapState({
    this.phase = AppBootstrapPhase.initial,
    this.criticalStartedAt,
    this.criticalCompletedAt,
    this.backgroundStartedAt,
    this.backgroundCompletedAt,
    this.errorMessage,
  });

  static const Object _noChange = Object();

  final AppBootstrapPhase phase;
  final DateTime? criticalStartedAt;
  final DateTime? criticalCompletedAt;
  final DateTime? backgroundStartedAt;
  final DateTime? backgroundCompletedAt;
  final String? errorMessage;

  bool get isCriticalReady {
    return phase == AppBootstrapPhase.criticalReady ||
        phase == AppBootstrapPhase.backgroundInitializing ||
        phase == AppBootstrapPhase.ready;
  }

  bool get isBackgroundReady => phase == AppBootstrapPhase.ready;

  /// Calculates comprehensive metrics from timing data.
  AppStartupMetrics? get metrics {
    final criticalStart = criticalStartedAt;
    final criticalEnd = criticalCompletedAt;

    if (criticalStart == null || criticalEnd == null) {
      return null;
    }

    final criticalTiming = AppBootstrapPhaseTiming(
      phaseName: 'critical',
      startedAt: criticalStart,
      completedAt: criticalEnd,
    );

    final backgroundStart = backgroundStartedAt;
    final backgroundEnd = backgroundCompletedAt;

    AppBootstrapPhaseTiming? backgroundTiming;
    if (backgroundStart != null && backgroundEnd != null) {
      backgroundTiming = AppBootstrapPhaseTiming(
        phaseName: 'background',
        startedAt: backgroundStart,
        completedAt: backgroundEnd,
      );
    }

    // Total startup time: from critical start to UI ready (critical end)
    final totalTime = Duration(
      milliseconds: criticalTiming.duration.inMilliseconds,
    );

    return AppStartupMetrics(
      criticalPhaseTiming: criticalTiming,
      backgroundPhaseTiming: backgroundTiming,
      totalStartupTime: totalTime,
    );
  }

  /// Checks if critical startup phase is healthy.
  AppBootstrapHealthCheck? checkCriticalHealth({int budgetMs = 3000}) {
    return metrics?.checkCriticalPhaseHealth(budgetMs: budgetMs);
  }

  /// Checks if background startup phase is healthy.
  AppBootstrapHealthCheck? checkBackgroundHealth({int budgetMs = 5000}) {
    return metrics?.checkBackgroundPhaseHealth(budgetMs: budgetMs);
  }

  /// Returns overall health status based on critical phase.
  AppBootstrapHealthStatus? get overallHealth {
    return checkCriticalHealth()?.status;
  }

  AppBootstrapState copyWith({
    AppBootstrapPhase? phase,
    DateTime? criticalStartedAt,
    DateTime? criticalCompletedAt,
    DateTime? backgroundStartedAt,
    DateTime? backgroundCompletedAt,
    Object? errorMessage = _noChange,
  }) {
    return AppBootstrapState(
      phase: phase ?? this.phase,
      criticalStartedAt: criticalStartedAt ?? this.criticalStartedAt,
      criticalCompletedAt: criticalCompletedAt ?? this.criticalCompletedAt,
      backgroundStartedAt: backgroundStartedAt ?? this.backgroundStartedAt,
      backgroundCompletedAt:
          backgroundCompletedAt ?? this.backgroundCompletedAt,
      errorMessage: identical(errorMessage, _noChange)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

final NotifierProvider<AppStartupOrchestrator, AppBootstrapState>
appStartupOrchestratorProvider =
    NotifierProvider<AppStartupOrchestrator, AppBootstrapState>(
      AppStartupOrchestrator.new,
    );

final Provider<AppBootstrapState> appBootstrapStateProvider =
    Provider<AppBootstrapState>((Ref ref) {
      return ref.watch(appStartupOrchestratorProvider);
    });

final class AppStartupOrchestrator extends Notifier<AppBootstrapState> {
  late final AppStartupServiceContract _startupService;
  Future<void>? _criticalInFlight;
  Future<void>? _backgroundInFlight;

  @override
  AppBootstrapState build() {
    _startupService = ref.watch(appStartupServiceProvider);
    return const AppBootstrapState();
  }

  Future<void> initializeCriticalState() async {
    if (state.isCriticalReady) {
      return;
    }

    final Future<void>? inFlight = _criticalInFlight;
    if (inFlight != null) {
      return inFlight;
    }

    final Future<void> next = _initializeCriticalStateInternal();
    _criticalInFlight = next;

    try {
      await next;
    } finally {
      if (identical(_criticalInFlight, next)) {
        _criticalInFlight = null;
      }
    }
  }

  Future<void> initializeBackgroundServices() async {
    if (state.isBackgroundReady) {
      return;
    }

    final Future<void>? inFlight = _backgroundInFlight;
    if (inFlight != null) {
      return inFlight;
    }

    final Future<void> next = _initializeBackgroundServicesInternal();
    _backgroundInFlight = next;

    try {
      await next;
    } finally {
      if (identical(_backgroundInFlight, next)) {
        _backgroundInFlight = null;
      }
    }
  }

  Future<void> _initializeCriticalStateInternal() async {
    final DateTime startedAt = DateTime.now().toUtc();
    state = state.copyWith(
      phase: AppBootstrapPhase.criticalInitializing,
      criticalStartedAt: startedAt,
      errorMessage: null,
    );

    try {
      await _startupService.initializeCriticalState();
    } catch (error, stackTrace) {
      AppLogger.instance.error(
        'Critical startup state initialization failed.',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        phase: AppBootstrapPhase.degraded,
        errorMessage: error.toString(),
      );
      rethrow;
    }

    state = state.copyWith(
      phase: AppBootstrapPhase.criticalReady,
      criticalCompletedAt: DateTime.now().toUtc(),
      errorMessage: null,
    );

    // Log critical phase metrics
    final metrics = state.metrics;
    if (metrics != null) {
      AppLogger.instance.info(
        'Critical startup phase completed. ${metrics.summary}',
      );
      final healthCheck = state.checkCriticalHealth();
      if (healthCheck != null) {
        AppLogger.instance.info('Health check: $healthCheck');
      }
    }
  }

  Future<void> _initializeBackgroundServicesInternal() async {
    if (!state.isCriticalReady) {
      state = state.copyWith(
        phase: AppBootstrapPhase.criticalReady,
      );
    }

    state = state.copyWith(
      phase: AppBootstrapPhase.backgroundInitializing,
      backgroundStartedAt: DateTime.now().toUtc(),
      errorMessage: null,
    );

    try {
      await _startupService.initializeBackgroundServices();
    } catch (error, stackTrace) {
      AppLogger.instance.error(
        'Background startup services orchestration failed.',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        phase: AppBootstrapPhase.degraded,
        errorMessage: error.toString(),
      );
      return;
    }

    state = state.copyWith(
      phase: AppBootstrapPhase.ready,
      backgroundCompletedAt: DateTime.now().toUtc(),
      errorMessage: null,
    );

    // Log background phase metrics
    final metrics = state.metrics;
    if (metrics != null && metrics.backgroundPhaseTiming != null) {
      AppLogger.instance.info(
        'Background startup phase completed. ${metrics.backgroundPhaseTiming}',
      );
      final healthCheck = state.checkBackgroundHealth();
      if (healthCheck != null) {
        AppLogger.instance.info('Background health check: $healthCheck');
      }
    }
  }
}

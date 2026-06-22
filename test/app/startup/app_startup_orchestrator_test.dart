import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_airsoft_app/src/app/services/app_startup_service.dart';
import 'package:global_airsoft_app/src/app/startup/app_startup_orchestrator.dart';

final class _FakeStartupService implements AppStartupServiceContract {
  int criticalCalls = 0;
  int backgroundCalls = 0;
  Completer<void>? criticalCompleter;
  Completer<void>? backgroundCompleter;
  Object? criticalError;
  Object? backgroundError;

  @override
  Future<void> initializeCriticalState() async {
    criticalCalls += 1;
    final Object? error = criticalError;
    if (error != null) {
      throw error;
    }

    final Completer<void>? completer = criticalCompleter;
    if (completer != null) {
      await completer.future;
    }
  }

  @override
  Future<void> initializeBackgroundServices() async {
    backgroundCalls += 1;
    final Object? error = backgroundError;
    if (error != null) {
      throw error;
    }

    final Completer<void>? completer = backgroundCompleter;
    if (completer != null) {
      await completer.future;
    }
  }
}

void main() {
  test('critical initialization transitions to criticalReady', () async {
    final _FakeStartupService fakeService = _FakeStartupService();
    final ProviderContainer container = ProviderContainer(
      overrides: [
        appStartupServiceProvider.overrideWithValue(fakeService),
      ],
    );
    addTearDown(container.dispose);

    final AppStartupOrchestrator orchestrator = container.read(
      appStartupOrchestratorProvider.notifier,
    );

    expect(
      container.read(appBootstrapStateProvider).phase,
      AppBootstrapPhase.initial,
    );

    await orchestrator.initializeCriticalState();

    final AppBootstrapState state = container.read(appBootstrapStateProvider);
    expect(fakeService.criticalCalls, 1);
    expect(state.phase, AppBootstrapPhase.criticalReady);
    expect(state.criticalStartedAt, isNotNull);
    expect(state.criticalCompletedAt, isNotNull);
    expect(state.errorMessage, isNull);
  });

  test('critical initialization is single-flight when called concurrently', () async {
    final _FakeStartupService fakeService = _FakeStartupService()
      ..criticalCompleter = Completer<void>();
    final ProviderContainer container = ProviderContainer(
      overrides: [
        appStartupServiceProvider.overrideWithValue(fakeService),
      ],
    );
    addTearDown(container.dispose);

    final AppStartupOrchestrator orchestrator = container.read(
      appStartupOrchestratorProvider.notifier,
    );

    final Future<void> first = orchestrator.initializeCriticalState();
    final Future<void> second = orchestrator.initializeCriticalState();

    await Future<void>.delayed(Duration.zero);
    expect(fakeService.criticalCalls, 1);
    expect(
      container.read(appBootstrapStateProvider).phase,
      AppBootstrapPhase.criticalInitializing,
    );

    fakeService.criticalCompleter?.complete();
    await Future.wait<void>(<Future<void>>[first, second]);

    expect(fakeService.criticalCalls, 1);
    expect(
      container.read(appBootstrapStateProvider).phase,
      AppBootstrapPhase.criticalReady,
    );
  });

  test('background initialization transitions to ready', () async {
    final _FakeStartupService fakeService = _FakeStartupService();
    final ProviderContainer container = ProviderContainer(
      overrides: [
        appStartupServiceProvider.overrideWithValue(fakeService),
      ],
    );
    addTearDown(container.dispose);

    final AppStartupOrchestrator orchestrator = container.read(
      appStartupOrchestratorProvider.notifier,
    );

    await orchestrator.initializeCriticalState();
    await orchestrator.initializeBackgroundServices();

    final AppBootstrapState state = container.read(appBootstrapStateProvider);
    expect(fakeService.criticalCalls, 1);
    expect(fakeService.backgroundCalls, 1);
    expect(state.phase, AppBootstrapPhase.ready);
    expect(state.backgroundStartedAt, isNotNull);
    expect(state.backgroundCompletedAt, isNotNull);
    expect(state.errorMessage, isNull);
  });

  test('critical initialization failure transitions to degraded', () async {
    final _FakeStartupService fakeService = _FakeStartupService()
      ..criticalError = StateError('critical failed');
    final ProviderContainer container = ProviderContainer(
      overrides: [
        appStartupServiceProvider.overrideWithValue(fakeService),
      ],
    );
    addTearDown(container.dispose);

    final AppStartupOrchestrator orchestrator = container.read(
      appStartupOrchestratorProvider.notifier,
    );

    await expectLater(
      orchestrator.initializeCriticalState(),
      throwsA(isA<StateError>()),
    );

    final AppBootstrapState state = container.read(appBootstrapStateProvider);
    expect(fakeService.criticalCalls, 1);
    expect(state.phase, AppBootstrapPhase.degraded);
    expect(state.errorMessage, contains('critical failed'));
  });
}

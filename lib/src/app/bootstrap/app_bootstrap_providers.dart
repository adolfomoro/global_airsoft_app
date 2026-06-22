import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/app/bootstrap/app_dependencies_bootstrapper.dart';
import 'package:global_airsoft_app/src/features/auth/domain/models/auth_tokens.dart';

/// Holds bootstrap data during app startup.
/// This provider is overridden with actual data in main.dart
/// so that all downstream providers can access initialized dependencies.
final Provider<AppDependenciesBootstrapData> appBootstrapDataProvider =
    Provider<AppDependenciesBootstrapData>(
  (_) => throw UnimplementedError(
    'appBootstrapDataProvider must be overridden in main',
  ),
);

/// Initial app locale from device.
/// Derived from bootstrap data.
final Provider<Locale> initialAppLocaleProvider = Provider<Locale>(
  (Ref ref) {
    final AppDependenciesBootstrapData bootstrapData =
        ref.watch(appBootstrapDataProvider);
    return bootstrapData.localeBootstrapData.initialUiLocale;
  },
);

/// Initial auth tokens.
/// Derived from bootstrap data.
final Provider<AuthTokens?> initialAuthTokensProvider =
    Provider<AuthTokens?>(
  (Ref ref) {
    final AppDependenciesBootstrapData bootstrapData =
        ref.watch(appBootstrapDataProvider);
    return bootstrapData.initialAuthTokens;
  },
);

/// Callback for cleaning up local auth session.
/// This provider is overridden in main because it requires access to
/// container.read(userProfileStorageServiceProvider) and container.invalidate().
final Provider<Future<void> Function()> authLocalSessionCleanupProvider =
    Provider<Future<void> Function()>(
  (_) => throw UnimplementedError(
    'authLocalSessionCleanupProvider must be overridden in main',
  ),
);

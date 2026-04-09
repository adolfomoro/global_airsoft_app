import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/app/theme/theme_dependency_providers.dart';
import 'package:global_airsoft_app/src/app/theme/theme_preference.dart';
import 'package:global_airsoft_app/src/app/theme/theme_preference_service.dart';
import 'package:global_airsoft_app/src/core/logging/app_logger.dart';

final class ThemePreferenceController extends Notifier<ThemeMode> {
  late final ThemePreferenceService _service;
  late AppThemePreference _currentPreference;

  @override
  ThemeMode build() {
    _service = ref.watch(themePreferenceServiceProvider);
    _currentPreference = ref.watch(initialThemePreferenceProvider);
    return _currentPreference.themeMode;
  }

  AppThemePreference get currentPreference => _currentPreference;

  Future<void> setPreference(AppThemePreference preference) async {
    if (_currentPreference == preference) {
      return;
    }

    final AppThemePreference previousPreference = _currentPreference;
    _currentPreference = preference;
    state = preference.themeMode;

    try {
      await _service.savePreference(preference);
    } catch (error, stackTrace) {
      _currentPreference = previousPreference;
      state = previousPreference.themeMode;
      AppLogger.instance.error(
        'Failed to persist theme preference',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> toggle() async {
    final AppThemePreference targetPreference =
        _currentPreference == AppThemePreference.dark
        ? AppThemePreference.light
        : AppThemePreference.dark;
    await setPreference(targetPreference);
  }
}

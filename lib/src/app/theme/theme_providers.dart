import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/app/theme/theme_preference.dart';
import 'package:global_airsoft_app/src/app/theme/theme_preference_controller.dart';
import 'package:global_airsoft_app/src/app/theme/theme_preference_service.dart';

final Provider<ThemePreferenceService> themePreferenceServiceProvider =
    Provider<ThemePreferenceService>(
      (Ref ref) => throw UnimplementedError('ThemePreferenceService not set.'),
    );

final Provider<AppThemePreference> initialThemePreferenceProvider =
    Provider<AppThemePreference>((Ref ref) => AppThemePreference.dark);

final StateNotifierProvider<ThemePreferenceController, ThemeMode>
themePreferenceControllerProvider =
    StateNotifierProvider<ThemePreferenceController, ThemeMode>((Ref ref) {
      final ThemePreferenceService service = ref.watch(
        themePreferenceServiceProvider,
      );
      final AppThemePreference initialPreference = ref.watch(
        initialThemePreferenceProvider,
      );

      return ThemePreferenceController(
        service: service,
        initialPreference: initialPreference,
      );
    });

final Provider<AppThemePreference> selectedThemePreferenceProvider =
    Provider<AppThemePreference>((Ref ref) {
      final ThemeMode currentMode = ref.watch(
        themePreferenceControllerProvider,
      );
      switch (currentMode) {
        case ThemeMode.light:
          return AppThemePreference.light;
        case ThemeMode.dark:
          return AppThemePreference.dark;
        case ThemeMode.system:
          return AppThemePreference.dark;
      }
    });

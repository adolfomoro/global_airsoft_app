import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/app/theme/theme_preference.dart';
import 'package:global_airsoft_app/src/app/theme/theme_preference_controller.dart';

export 'package:global_airsoft_app/src/app/theme/theme_dependency_providers.dart';

final NotifierProvider<ThemePreferenceController, ThemeMode>
themePreferenceControllerProvider =
    NotifierProvider<ThemePreferenceController, ThemeMode>(
      ThemePreferenceController.new,
    );

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

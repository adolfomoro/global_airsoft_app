import 'package:flutter/material.dart';

enum AppThemePreference { dark, light }

extension AppThemePreferenceX on AppThemePreference {
  ThemeMode get themeMode {
    switch (this) {
      case AppThemePreference.dark:
        return ThemeMode.dark;
      case AppThemePreference.light:
        return ThemeMode.light;
    }
  }

  Brightness get brightness {
    switch (this) {
      case AppThemePreference.dark:
        return Brightness.dark;
      case AppThemePreference.light:
        return Brightness.light;
    }
  }

  String get storageValue {
    switch (this) {
      case AppThemePreference.dark:
        return 'dark';
      case AppThemePreference.light:
        return 'light';
    }
  }

  static AppThemePreference fromStorageValue(String? rawValue) {
    switch (rawValue) {
      case 'light':
        return AppThemePreference.light;
      case 'dark':
      default:
        return AppThemePreference.dark;
    }
  }
}

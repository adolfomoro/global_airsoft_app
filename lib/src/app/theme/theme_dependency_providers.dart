import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/app/theme/theme_preference.dart';
import 'package:global_airsoft_app/src/app/theme/theme_preference_service.dart';

final Provider<ThemePreferenceService> themePreferenceServiceProvider =
    Provider<ThemePreferenceService>(
      (Ref ref) => throw UnimplementedError('ThemePreferenceService not set.'),
    );

final Provider<AppThemePreference> initialThemePreferenceProvider =
    Provider<AppThemePreference>((Ref ref) => AppThemePreference.dark);
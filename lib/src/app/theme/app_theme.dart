import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:global_airsoft_app/src/app/theme/app_colors.dart';
import 'package:global_airsoft_app/src/app/theme/app_dimensions.dart';

final class AppTheme {
  AppTheme._();

  static final ColorScheme _lightColorScheme = const ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onBackground,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onSecondary,
    secondaryContainer: AppColors.secondaryLight,
    onSecondaryContainer: AppColors.background,
    tertiary: AppColors.accentGreenDark,
    onTertiary: AppColors.onBackground,
    tertiaryContainer: AppColors.surfaceVariant,
    onTertiaryContainer: AppColors.onSurface,
    error: AppColors.error,
    onError: AppColors.onBackground,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.onBackground,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    onSurfaceVariant: AppColors.onSurfaceDim,
    outline: AppColors.outline,
    outlineVariant: AppColors.outlineVariant,
    shadow: AppColors.accentBlack,
    scrim: AppColors.accentBlack,
    inverseSurface: AppColors.onBackground,
    onInverseSurface: AppColors.background,
    inversePrimary: AppColors.primary,
    surfaceTint: AppColors.primary,
  );

  static final ColorScheme _darkColorScheme = const ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.secondaryLight,
    onPrimary: AppColors.background,
    primaryContainer: AppColors.primary,
    onPrimaryContainer: AppColors.onBackground,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onSecondary,
    secondaryContainer: AppColors.surfaceVariant,
    onSecondaryContainer: AppColors.onBackground,
    tertiary: AppColors.secondaryLight,
    onTertiary: AppColors.background,
    tertiaryContainer: AppColors.accentGreenDark,
    onTertiaryContainer: AppColors.onBackground,
    error: AppColors.error,
    onError: AppColors.onBackground,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.onBackground,
    surface: AppColors.background,
    onSurface: AppColors.onBackground,
    onSurfaceVariant: AppColors.onSurfaceDim,
    outline: AppColors.outline,
    outlineVariant: AppColors.outlineVariant,
    shadow: AppColors.accentBlack,
    scrim: AppColors.accentBlack,
    inverseSurface: AppColors.onBackground,
    onInverseSurface: AppColors.background,
    inversePrimary: AppColors.primary,
    surfaceTint: AppColors.primary,
  );

  static ThemeData get light => _buildTheme(_lightColorScheme);

  static ThemeData get dark => _buildTheme(_darkColorScheme);

  static SystemUiOverlayStyle overlayStyleFor(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: AppColors.transparent,
      systemNavigationBarColor: AppColors.transparent,
      systemNavigationBarDividerColor: AppColors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarIconBrightness: isDark
          ? Brightness.light
          : Brightness.dark,
    );
  }

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    final bool isDark = colorScheme.brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: AppColors.transparent,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: overlayStyleFor(colorScheme.brightness),
      ),
      cardTheme: CardThemeData(
        color: isDark ? AppColors.backgroundMid : AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppDimensions.controlHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppDimensions.controlHeight),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppDimensions.controlHeight),
          side: BorderSide(color: colorScheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.backgroundMid : AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingLg,
          vertical: AppDimensions.spacingLg,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.surfaceVariant : AppColors.surface,
        contentTextStyle: const TextStyle(color: AppColors.onBackground),
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}

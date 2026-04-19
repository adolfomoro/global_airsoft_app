import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:global_airsoft_app/src/app/theme/app_colors.dart';
import 'package:global_airsoft_app/src/app/theme/app_dimensions.dart';
import 'package:google_fonts/google_fonts.dart';

final class AppTheme {
  AppTheme._();

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
    final TextTheme baseTextTheme = ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
    ).textTheme;
    final TextTheme robotoFlexTextTheme = GoogleFonts.robotoFlexTextTheme(
      baseTextTheme,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: robotoFlexTextTheme,
      primaryTextTheme: robotoFlexTextTheme,
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
        color: AppColors.backgroundMid,
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
        fillColor: AppColors.backgroundMid,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingXl,
          vertical: 16,
        ),
        isDense: false,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        labelStyle: const TextStyle(
          color: AppColors.onSurfaceDim,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        floatingLabelStyle: const TextStyle(
          color: AppColors.secondaryLight,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: const TextStyle(color: AppColors.onSurfaceDim),
        prefixIconColor: AppColors.secondaryLight,
        suffixIconColor: AppColors.onSurfaceDim,
        prefixIconConstraints: const BoxConstraints(
          minWidth: 48,
          minHeight: 48,
        ),
        suffixIconConstraints: const BoxConstraints(
          minWidth: 48,
          minHeight: 48,
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
          borderSide: BorderSide(color: colorScheme.primary, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          borderSide: BorderSide(color: colorScheme.error, width: 1.1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          borderSide: BorderSide(color: colorScheme.error, width: 1.2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceVariant,
        contentTextStyle: const TextStyle(color: AppColors.onBackground),
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}

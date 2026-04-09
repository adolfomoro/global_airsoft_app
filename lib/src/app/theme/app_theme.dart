import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:global_airsoft_app/src/app/theme/app_colors.dart';

final class AppTheme {
  AppTheme._();

  static final ColorScheme _lightColorScheme = const ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.olive700,
    onPrimary: Colors.white,
    primaryContainer: AppColors.olive300,
    onPrimaryContainer: AppColors.slate950,
    secondary: AppColors.sand700,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.sand200,
    onSecondaryContainer: AppColors.slate950,
    tertiary: AppColors.rust600,
    onTertiary: Colors.white,
    tertiaryContainer: AppColors.rust400,
    onTertiaryContainer: Colors.white,
    error: Color(0xFFB3261E),
    onError: Colors.white,
    errorContainer: Color(0xFFF9DEDC),
    onErrorContainer: Color(0xFF410E0B),
    surface: AppColors.mist50,
    onSurface: AppColors.slate950,
    onSurfaceVariant: AppColors.slate700,
    outline: AppColors.sand500,
    outlineVariant: AppColors.sand200,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: AppColors.slate900,
    onInverseSurface: AppColors.mist100,
    inversePrimary: AppColors.olive300,
    surfaceTint: AppColors.olive700,
  );

  static final ColorScheme _darkColorScheme = const ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.olive300,
    onPrimary: AppColors.slate950,
    primaryContainer: AppColors.olive700,
    onPrimaryContainer: AppColors.mist100,
    secondary: AppColors.sand500,
    onSecondary: AppColors.slate950,
    secondaryContainer: AppColors.sand700,
    onSecondaryContainer: AppColors.mist100,
    tertiary: AppColors.rust400,
    onTertiary: AppColors.slate950,
    tertiaryContainer: AppColors.rust600,
    onTertiaryContainer: AppColors.mist100,
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: AppColors.slate950,
    onSurface: AppColors.mist100,
    onSurfaceVariant: AppColors.sand200,
    outline: AppColors.sand500,
    outlineVariant: AppColors.slate700,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: AppColors.mist100,
    onInverseSurface: AppColors.slate950,
    inversePrimary: AppColors.olive700,
    surfaceTint: AppColors.olive300,
  );

  static ThemeData get light => _buildTheme(_lightColorScheme);

  static ThemeData get dark => _buildTheme(_darkColorScheme);

  static SystemUiOverlayStyle overlayStyleFor(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
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
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: overlayStyleFor(colorScheme.brightness),
      ),
      cardTheme: CardThemeData(
        color: isDark ? AppColors.slate900 : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: colorScheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.slate900 : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.slate700 : AppColors.slate900,
        contentTextStyle: TextStyle(color: AppColors.mist100),
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}

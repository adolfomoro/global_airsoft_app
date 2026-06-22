import 'package:flutter/material.dart';

final class AppPalette {
  const AppPalette({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.surface3,
    required this.surface4,
    required this.border,
    required this.borderSoft,
    required this.borderStrong,
    required this.text,
    required this.text2,
    required this.muted,
    required this.muted2,
    required this.accent50,
    required this.accent100,
    required this.accent200,
    required this.accent300,
    required this.accent400,
    required this.accent,
    required this.accent600,
    required this.accentPress,
    required this.accent800,
    required this.accentTint,
    required this.success,
    required this.successTint,
    required this.warning,
    required this.warningTint,
    required this.danger,
    required this.dangerTint,
    required this.info,
    required this.infoTint,
    required this.win,
    required this.loss,
    required this.mvp,
  });

  static const AppPalette rangerGreen = AppPalette(
    bg: Color(0xFF0E110A),
    surface: Color(0xFF16190F),
    surface2: Color(0xFF1E2316),
    surface3: Color(0xFF2C331F),
    surface4: Color(0xFF3A4329),
    border: Color(0xFF2C331F),
    borderSoft: Color(0xFF1E2316),
    borderStrong: Color(0xFF3A4329),
    text: Color(0xFFECEEE3),
    text2: Color(0xFFC7CBB8),
    muted: Color(0xFF8E947E),
    muted2: Color(0xFF5F6552),
    accent50: Color(0xFFEDF3DC),
    accent100: Color(0xFFD6E4B0),
    accent200: Color(0xFFBCD382),
    accent300: Color(0xFFA3C26B),
    accent400: Color(0xFF8FB551),
    accent: Color(0xFF7FA942),
    accent600: Color(0xFF688E32),
    accentPress: Color(0xFF557528),
    accent800: Color(0xFF3F571C),
    accentTint: Color(0x297FA942),
    success: Color(0xFF5BB85C),
    successTint: Color(0x295BB85C),
    warning: Color(0xFFE8A93C),
    warningTint: Color(0x29E8A93C),
    danger: Color(0xFFE0524E),
    dangerTint: Color(0x24E0524E),
    info: Color(0xFF4D9BD1),
    infoTint: Color(0x294D9BD1),
    win: Color(0xFF5BB85C),
    loss: Color(0xFFE0524E),
    mvp: Color(0xFFA3C26B),
  );

  final Color bg;
  final Color surface;
  final Color surface2;
  final Color surface3;
  final Color surface4;
  final Color border;
  final Color borderSoft;
  final Color borderStrong;
  final Color text;
  final Color text2;
  final Color muted;
  final Color muted2;
  final Color accent50;
  final Color accent100;
  final Color accent200;
  final Color accent300;
  final Color accent400;
  final Color accent;
  final Color accent600;
  final Color accentPress;
  final Color accent800;
  final Color accentTint;
  final Color success;
  final Color successTint;
  final Color warning;
  final Color warningTint;
  final Color danger;
  final Color dangerTint;
  final Color info;
  final Color infoTint;
  final Color win;
  final Color loss;
  final Color mvp;
}

abstract final class AppColors {
  static const AppPalette palette = AppPalette.rangerGreen;

  static Color get background => palette.bg;
  static Color get backgroundMid => palette.surface;
  static Color get shimmerBackground => palette.surface2;
  static Color get shimmerHighlight => palette.surface4;
  static Color get surface => palette.surface;
  static Color get surfaceVariant => palette.surface3;

  static Color get primary => palette.accent;
  static Color get primaryContainer => palette.accentPress;
  static Color get onPrimary => palette.bg;

  static Color get secondary => palette.accent300;
  static Color get secondaryLight => palette.accent300;
  static Color get onSecondary => palette.bg;

  static Color get onBackground => palette.text;
  static Color get onSurface => palette.text;
  static Color get onSurfaceDim => palette.muted;

  static Color get outline => palette.border;
  static Color get outlineVariant => palette.borderStrong;
  static Color get outlineLight => palette.muted2;

  static Color get accentGray => palette.muted2;
  static Color get accentGreenDark => palette.accent800;
  static const Color accentBlack = Color(0xFF000000);

  static Color get error => palette.danger;
  static Color get errorContainer => palette.dangerTint;
  static Color get success => palette.success;
  static Color get warning => palette.warning;
  static Color get info => palette.info;

  static const Color googleBlue = Color(0xFF4285F4);
  static const Color googleIconColor = googleBlue;

  static const Color white70 = Color(0xB3FFFFFF);
  static const Color black87 = Color(0xDD000000);

  static Color get spinnerDark => palette.muted;
  static Color get spinnerLight => palette.muted2;

  static const Color shadowDark = Color(0x4D000000);
  static const Color shadowLight = Color(0x1A000000);
  static const Color overlayDark = Color(0x80000000);

  static const Color white = Color(0xFFFFFFFF);
  static const Color transparent = Color(0x00000000);
}

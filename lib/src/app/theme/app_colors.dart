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

  static const AppPalette emberOrange = AppPalette(
    bg: Color(0xFF120D08),
    surface: Color(0xFF1A120C),
    surface2: Color(0xFF241811),
    surface3: Color(0xFF322118),
    surface4: Color(0xFF432B1E),
    border: Color(0xFF322118),
    borderSoft: Color(0xFF241811),
    borderStrong: Color(0xFF5A3924),
    text: Color(0xFFF4E7DC),
    text2: Color(0xFFD9C4B2),
    muted: Color(0xFFB3957F),
    muted2: Color(0xFF7A5E4A),
    accent50: Color(0xFFFFF3E8),
    accent100: Color(0xFFFFDEC2),
    accent200: Color(0xFFFFC38F),
    accent300: Color(0xFFF6A85A),
    accent400: Color(0xFFEE9137),
    accent: Color(0xFFE67E22),
    accent600: Color(0xFFBF6518),
    accentPress: Color(0xFF9B5014),
    accent800: Color(0xFF6F390E),
    accentTint: Color(0x29E67E22),
    success: Color(0xFF63C174),
    successTint: Color(0x2963C174),
    warning: Color(0xFFF2B94B),
    warningTint: Color(0x29F2B94B),
    danger: Color(0xFFE6675E),
    dangerTint: Color(0x24E6675E),
    info: Color(0xFF63A8E2),
    infoTint: Color(0x2963A8E2),
    win: Color(0xFF63C174),
    loss: Color(0xFFE6675E),
    mvp: Color(0xFFF6A85A),
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
  static const AppPalette palette = AppPalette.emberOrange;

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

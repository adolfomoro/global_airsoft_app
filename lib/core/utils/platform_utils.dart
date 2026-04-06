import 'dart:io';

import 'package:flutter/material.dart';

/// Platform detection utilities for iOS/Android specific handling
abstract final class PlatformUtils {
  static bool get isIOS => !isAndroid;
  static bool get isAndroid => Platform.isAndroid;

  /// iOS uses different SafeArea padding for notch/home indicator
  /// Android needs safe area only for status bar
  static EdgeInsets safeAreaPadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    if (isIOS) {
      // iOS: respect notch and home indicator
      return EdgeInsets.only(
        top: mediaQuery.padding.top,
        bottom: mediaQuery.padding.bottom,
        left: mediaQuery.padding.left,
        right: mediaQuery.padding.right,
      );
    } else {
      // Android: only top padding needed (status bar)
      return EdgeInsets.only(top: mediaQuery.padding.top);
    }
  }

  /// Responsive horizontal padding based on screen size
  static double responsiveHorizontalPadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 360) {
      return 12;
    } else if (screenWidth < 720) {
      return 16;
    } else {
      return 24;
    }
  }

  /// Minimum touch target size (iOS: 44x44, Android: 48x48)
  /// Flutter uses 48x48 by default which is safe for both
  static const double minTouchSize = 48;
}

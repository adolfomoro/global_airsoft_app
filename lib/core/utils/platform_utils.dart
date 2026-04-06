import 'dart:io';

import 'package:flutter/material.dart';

abstract final class PlatformUtils {
  static bool get isIOS => !isAndroid;
  static bool get isAndroid => Platform.isAndroid;

  static EdgeInsets safeAreaPadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    if (isIOS) {
      return EdgeInsets.only(
        top: mediaQuery.padding.top,
        bottom: mediaQuery.padding.bottom,
        left: mediaQuery.padding.left,
        right: mediaQuery.padding.right,
      );
    } else {
      return EdgeInsets.only(top: mediaQuery.padding.top);
    }
  }

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

  static const double minTouchSize = 48;
}

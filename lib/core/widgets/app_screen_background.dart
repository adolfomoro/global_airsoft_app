import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppScreenBackground extends StatelessWidget {
  const AppScreenBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Optimized gradient with smooth color transitions
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.background,
                AppColors.backgroundMid,
                AppColors.surface,
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),
        child,
      ],
    );
  }
}

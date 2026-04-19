import 'package:flutter/material.dart';
import 'package:global_airsoft_app/src/app/theme/app_colors.dart';
import 'package:shimmer/shimmer.dart';

enum AppSkeletonShape { rectangle, circle }

class AppSkeleton extends StatelessWidget {
  const AppSkeleton({
    this.width,
    this.height,
    this.shape = AppSkeletonShape.rectangle,
    this.borderRadius,
    super.key,
  });

  const AppSkeleton.circle({required double size, super.key})
    : width = size,
      height = size,
      shape = AppSkeletonShape.circle,
      borderRadius = null;

  static const Duration _shimmerDuration = Duration(milliseconds: 1190);
  static final BorderRadiusGeometry _defaultBorderRadius =
      BorderRadius.circular(12);

  final double? width;
  final double? height;
  final AppSkeletonShape shape;
  final BorderRadiusGeometry? borderRadius;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Shimmer.fromColors(
        period: _shimmerDuration,
        baseColor: AppColors.shimmerBackground,
        highlightColor: AppColors.shimmerHighlight,
        direction: ShimmerDirection.ltr,
        enabled: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: shape == AppSkeletonShape.circle
                ? BoxShape.circle
                : BoxShape.rectangle,
            borderRadius: shape == AppSkeletonShape.circle
                ? null
                : borderRadius ?? _defaultBorderRadius,
            color: AppColors.shimmerBackground,
          ),
        ),
      ),
    );
  }
}

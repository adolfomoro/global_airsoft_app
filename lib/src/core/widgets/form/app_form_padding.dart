import 'package:flutter/material.dart';
import 'package:global_airsoft_app/src/app/theme/app_dimensions.dart';

final class AppFormPadding extends StatelessWidget {
  static const EdgeInsets _defaultPadding = EdgeInsets.symmetric(
    horizontal: AppDimensions.spacing2xl,
  );

  const AppFormPadding({
    super.key,
    required this.child,
    this.padding = _defaultPadding,
    this.maxWidth = AppDimensions.maxContentWidth,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    Widget content = child;
    if (maxWidth != null) {
      content = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth!),
        child: content,
      );
    }

    return Padding(
      padding: padding,
      child: Align(alignment: Alignment.topCenter, child: content),
    );
  }
}

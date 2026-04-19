import 'package:flutter/material.dart';
import 'package:global_airsoft_app/src/app/theme/app_dimensions.dart';

final class AppFormPadding extends StatelessWidget {
  static const EdgeInsets _defaultPadding = EdgeInsets.all(
    AppDimensions.spacing2xl,
  );

  const AppFormPadding({
    super.key,
    required this.child,
    this.padding = _defaultPadding,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(padding: padding, child: child);
  }
}

import 'package:flutter/material.dart';

final class AppGradientBackground extends StatelessWidget {
  const AppGradientBackground({
    super.key,
    required this.child,
    this.colors,
    this.begin = Alignment.topCenter,
    this.end = Alignment.bottomCenter,
    this.stops,
  });

  final Widget child;
  final List<Color>? colors;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;
  final List<double>? stops;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final List<Color> effectiveColors =
        colors ??
        <Color>[
          colorScheme.primaryContainer.withOpacity(0.20),
          colorScheme.surface,
          colorScheme.surface,
        ];

    return SizedBox.expand(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: begin,
            end: end,
            colors: effectiveColors,
            stops: stops,
          ),
        ),
        child: child,
      ),
    );
  }
}

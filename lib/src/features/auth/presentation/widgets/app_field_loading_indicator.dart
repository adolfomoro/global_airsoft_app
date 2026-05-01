import 'package:flutter/material.dart';

final class AppFieldLoadingIndicator extends StatelessWidget {
  const AppFieldLoadingIndicator({
    super.key,
    this.size = 18,
    this.slotSize = 48,
    this.strokeWidth = 2,
    this.semanticsLabel,
  });

  final double size;
  final double slotSize;
  final double strokeWidth;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final Color color = Theme.of(context).colorScheme.onSurfaceVariant;
    final Widget indicator = SizedBox.square(
      dimension: slotSize,
      child: Center(
        child: SizedBox.square(
          dimension: size,
          child: CircularProgressIndicator(
            strokeWidth: strokeWidth,
            color: color,
          ),
        ),
      ),
    );

    final String? label = semanticsLabel;
    if (label == null || label.trim().isEmpty) {
      return indicator;
    }

    return Semantics(label: label, liveRegion: true, child: indicator);
  }
}

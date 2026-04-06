import 'package:flutter/material.dart';

/// High-performance wrapper that unfocuses any focused field when tapping
/// Uses Listener to detect pointer events without interfering with interactions
class AppUnfocusWrapper extends StatelessWidget {
  const AppUnfocusWrapper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Listener(
      // Detect all pointer down events (taps, clicks, etc)
      onPointerDown: (_) {
        // Unfocus the currently focused field
        FocusScope.of(context).unfocus();
      },
      // Allow all events to propagate normally
      child: child,
    );
  }
}

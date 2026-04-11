import 'package:flutter/material.dart';

class AppUnfocusWrapper extends StatelessWidget {
  const AppUnfocusWrapper({super.key, required this.child});

  final Widget child;

  void _handleTap() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _handleTap,
      child: child,
    );
  }
}

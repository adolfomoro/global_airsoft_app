import 'package:flutter/material.dart';

class AppUnfocusWrapper extends StatelessWidget {
  const AppUnfocusWrapper({super.key, required this.child});

  final Widget child;

  void _handlePointerDown(PointerDownEvent event) {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(onPointerDown: _handlePointerDown, child: child);
  }
}

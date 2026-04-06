import 'package:flutter/material.dart';

class AppUnfocusWrapper extends StatelessWidget {
  const AppUnfocusWrapper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {
        FocusScope.of(context).unfocus();
      },
      child: child,
    );
  }
}

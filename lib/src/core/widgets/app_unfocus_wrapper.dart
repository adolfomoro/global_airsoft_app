import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppUnfocusWrapper extends StatelessWidget {
  const AppUnfocusWrapper({super.key, required this.child});

  final Widget child;

  void _handlePointerDown() {
    FocusManager.instance.primaryFocus?.unfocus();
    SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _handlePointerDown(),
      child: child,
    );
  }
}

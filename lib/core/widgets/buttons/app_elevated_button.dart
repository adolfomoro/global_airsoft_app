import 'package:flutter/material.dart';

import '../loading/app_loading_spinner.dart';
import '../../theme/app_spacing.dart';

class AppElevatedButton extends StatelessWidget {
  const AppElevatedButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.isLoading = false,
    this.disabled = false,
    this.icon,
  });

  final VoidCallback onPressed;
  final String label;
  final bool isLoading;
  final bool disabled;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final isEnabled = !isLoading && !disabled;

    return ElevatedButton(
      onPressed: isEnabled ? onPressed : null,
      child: isLoading
          ? AppLoadingSpinner.appLoadingSpinner
          : icon != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [icon!, AppSpacing.sizedBoxHorizontalSm, Text(label)],
            )
          : Text(label),
    );
  }
}

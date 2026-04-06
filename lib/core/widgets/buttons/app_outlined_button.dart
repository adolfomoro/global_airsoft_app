import 'package:flutter/material.dart';

import '../loading/app_loading_spinner.dart';
import '../../theme/app_spacing.dart';

/// Standard outlined button widget with loading and disabled states
/// Touch target: Same as ElevatedButton for consistency
class AppOutlinedButton extends StatelessWidget {
  const AppOutlinedButton({
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

    return OutlinedButton(
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

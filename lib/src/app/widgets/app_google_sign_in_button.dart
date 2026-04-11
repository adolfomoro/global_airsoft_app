import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:global_airsoft_app/src/app/theme/app_colors.dart';

final class AppGoogleSignInButton extends StatelessWidget {
  static const BorderRadius _borderRadius = BorderRadius.all(
    Radius.circular(6),
  );

  const AppGoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool isDisabled = onPressed == null || isLoading;
    final Color borderColor = isDisabled
        ? colorScheme.outlineVariant
        : const Color(0xFF8E918F);
    final Color textColor = isDisabled
        ? colorScheme.onSurfaceVariant
        : const Color(0xFFE3E3E3);

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: isDisabled ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFF131314),
          side: BorderSide(color: borderColor),
          shape: const RoundedRectangleBorder(borderRadius: _borderRadius),
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  FaIcon(
                    FontAwesomeIcons.google,
                    size: 16,
                    color: AppColors.googleBlue,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Sign In with Google',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

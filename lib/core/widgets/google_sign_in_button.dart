import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../theme/app_spacing.dart';
import '../theme/app_colors.dart';

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.disabled = false,
  });

  final VoidCallback? onPressed;
  final bool isLoading;
  final bool disabled;

  static const _googleLogoSpinner = SizedBox(
    height: 18,
    width: 18,
    child: CircularProgressIndicator(
      strokeWidth: 2,
      valueColor: AlwaysStoppedAnimation<Color>(AppColors.spinnerDark),
    ),
  );

  static const _googleIcon = FaIcon(
    FontAwesomeIcons.google,
    color: AppColors.googleBlue,
    size: 18,
  );

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 0,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: (isLoading || disabled) ? null : onPressed,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 52,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: isLoading
                  ? [_googleLogoSpinner]
                  : [
                      _googleIcon,
                      AppSpacing.sizedBoxHorizontalMd,
                      Flexible(
                        child: Text(
                          'Entrar com Google',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
            ),
          ),
        ),
      ),
    );
  }
}

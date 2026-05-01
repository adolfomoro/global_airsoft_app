import 'package:flutter/material.dart';
import 'package:global_airsoft_app/src/app/routing/app_route_paths.dart';
import 'package:global_airsoft_app/src/app/theme/app_dimensions.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/core/widgets/app_adaptive_app_bar.dart';
import 'package:global_airsoft_app/src/core/widgets/app_button.dart';

class PasswordRecoverySuccessPage extends StatelessWidget {
  const PasswordRecoverySuccessPage({required this.email, super.key});

  final String email;

  void _navigateBackToLogin(BuildContext context) {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutePaths.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppAdaptiveAppBar(
        title: Text(context.l10n.tr(AppLocaleKeys.authPasswordRecoveryTitle)),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spacing2xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const SizedBox(height: AppDimensions.spacing2xl),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.10),
                        blurRadius: AppDimensions.spacing2xl,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.mark_email_read_rounded,
                      size: 56,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  context.l10n.tr(
                    AppLocaleKeys.authPasswordRecoverySuccessTitle,
                  ),
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.spacingLg),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final message = context.l10n.tr(
                      AppLocaleKeys.authPasswordRecoverySuccessMessage,
                    );
                    final parts = message.split('{email}');
                    return RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                        children: [
                          TextSpan(text: parts.first),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              child: Text(
                                email,
                                style: textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                                softWrap: false,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          if (parts.length > 1) TextSpan(text: parts.last),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
                AppButton(
                  label: context.l10n.tr(AppLocaleKeys.authBackToLoginAction),
                  onPressed: () => _navigateBackToLogin(context),
                ),
                const SizedBox(height: AppDimensions.spacing2xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

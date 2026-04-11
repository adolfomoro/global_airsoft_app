import 'package:flutter/material.dart';
import 'package:global_airsoft_app/src/app/widgets/app_adaptive_app_bar.dart';
import 'package:global_airsoft_app/src/app/widgets/app_button.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';

class PasswordRecoverySuccessPage extends StatelessWidget {
  const PasswordRecoverySuccessPage({required this.email, super.key});

  final String email;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppAdaptiveAppBar(
        title: Text(context.l10n.tr(AppLocaleKeys.authPasswordRecoveryTitle)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 20),
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.mark_email_read_rounded,
                  size: 36,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                context.l10n.tr(AppLocaleKeys.authPasswordRecoverySuccessTitle),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                context.l10n.trArgs(
                  AppLocaleKeys.authPasswordRecoverySuccessMessage,
                  args: <String, Object>{'email': email},
                ),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const Spacer(),
              AppButton(
                label: context.l10n.tr(
                  AppLocaleKeys.authPasswordRecoverySuccessBackToLoginAction,
                ),
                onPressed: () {
                  Navigator.of(
                    context,
                  ).popUntil((Route<void> route) => route.isFirst);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

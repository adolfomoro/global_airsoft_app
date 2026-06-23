import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/core/widgets/app_bar/app_adaptive_app_bar.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/widgets/password_recovery_form_view.dart';

class PasswordRecoveryPage extends ConsumerWidget {
  const PasswordRecoveryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppAdaptiveAppBar(
        title: Text(context.l10n.tr(AppLocaleKeys.authPasswordRecoveryTitle)),
      ),
      body: const SafeArea(child: PasswordRecoveryFormView()),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/core/widgets/app_bar/app_adaptive_app_bar.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/widgets/google_account_setup_form_view.dart';

class GoogleAccountSetupPage extends ConsumerStatefulWidget {
  const GoogleAccountSetupPage({
    required this.challengeToken,
    required this.profilePictureUrl,
    required this.profileName,
    super.key,
  });

  final String challengeToken;
  final String profilePictureUrl;
  final String profileName;

  @override
  ConsumerState<GoogleAccountSetupPage> createState() =>
      _GoogleAccountSetupPageState();
}

class _GoogleAccountSetupPageState
    extends ConsumerState<GoogleAccountSetupPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAdaptiveAppBar(
        title: Text(context.l10n.tr(AppLocaleKeys.authGoogleAccountSetupTitle)),
      ),
      body: SafeArea(
        child: GoogleAccountSetupFormView(
          challengeToken: widget.challengeToken,
          profilePictureUrl: widget.profilePictureUrl,
          profileName: widget.profileName,
        ),
      ),
    );
  }
}

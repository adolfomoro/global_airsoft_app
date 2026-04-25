import 'package:flutter/material.dart';
import 'package:global_airsoft_app/src/app/widgets/app_adaptive_app_bar.dart';
import 'package:global_airsoft_app/src/app/widgets/app_button.dart';
import 'package:global_airsoft_app/src/app/widgets/app_form_with_bottom_actions.dart';
import 'package:global_airsoft_app/src/app/widgets/app_text_field.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/core/widgets/app_profile_image_zoom_viewer.dart';
import 'package:global_airsoft_app/src/core/widgets/app_profile_picture_editor.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/models/google_account_setup_arguments.dart';

class GoogleAccountSetupPage extends StatefulWidget {
  const GoogleAccountSetupPage({required this.arguments, super.key});

  final GoogleAccountSetupArguments arguments;

  @override
  State<GoogleAccountSetupPage> createState() => _GoogleAccountSetupPageState();
}

class _GoogleAccountSetupPageState extends State<GoogleAccountSetupPage> {
  late final TextEditingController _profileNameController =
      TextEditingController(text: widget.arguments.profileName);

  void _handleProfilePhotoTap(String profilePictureUrl) {
    if (profilePictureUrl.isEmpty) {
      return;
    }

    AppProfileImageZoomViewer.showNetwork(context, imageUrl: profilePictureUrl);
  }

  void _handleProfileEditTap() {
    _handleProfilePhotoTap(widget.arguments.profilePictureUrl.trim());
  }

  @override
  void dispose() {
    _profileNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String profilePictureUrl = widget.arguments.profilePictureUrl.trim();

    return Scaffold(
      appBar: AppAdaptiveAppBar(
        title: Text(context.l10n.tr(AppLocaleKeys.authGoogleAccountSetupTitle)),
      ),
      body: AppFormWithBottomActions(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SizedBox(height: 20),
            Text(
              context.l10n.tr(AppLocaleKeys.authGoogleAccountSetupSubtitle),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 40),
            Center(
              child: AppProfilePictureEditor.network(
                imageUrl: profilePictureUrl,
                onPhotoTap: () => _handleProfilePhotoTap(profilePictureUrl),
                onEditTap: _handleProfileEditTap,
              ),
            ),
            const SizedBox(height: 50),
            AppTextField(
              labelText: context.l10n.tr(AppLocaleKeys.authUsernameLabel),
              controller: _profileNameController,
            ),
            const SizedBox(height: 24),
          ],
        ),
        bottomActions: <AppFormBottomAction>[
          AppFormBottomAction(
            child: AppButton(
              label: context.l10n.tr(AppLocaleKeys.authSignUpAction),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}

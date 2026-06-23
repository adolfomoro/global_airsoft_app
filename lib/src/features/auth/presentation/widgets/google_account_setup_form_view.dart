import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:global_airsoft_app/src/app/theme/app_dimensions.dart';
import 'package:global_airsoft_app/src/core/forms/forms.dart' as app_forms;
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/core/media/profile_photo.dart';
import 'package:global_airsoft_app/src/core/widgets/app_bar/app_page_header.dart';
import 'package:global_airsoft_app/src/core/widgets/app_snack_bar_presenter.dart';
import 'package:global_airsoft_app/src/core/widgets/form/app_button.dart';
import 'package:global_airsoft_app/src/core/widgets/image/app_profile_image_zoom_viewer.dart';
import 'package:global_airsoft_app/src/core/widgets/image/profile_photo_editor.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/controllers/google_account_setup_form_controller.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/widgets/app_form_with_bottom_actions.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/widgets/username_availability_field.dart';

class GoogleAccountSetupFormView extends ConsumerStatefulWidget {
  const GoogleAccountSetupFormView({
    required this.challengeToken,
    required this.profilePictureUrl,
    required this.profileName,
    super.key,
  });

  final String challengeToken;
  final String profilePictureUrl;
  final String profileName;

  @override
  ConsumerState<GoogleAccountSetupFormView> createState() =>
      _GoogleAccountSetupFormViewState();
}

class _GoogleAccountSetupFormViewState
    extends ConsumerState<GoogleAccountSetupFormView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;

  @override
  void initState() {
    super.initState();

    final GoogleAccountSetupFormController controller = ref.read(
      googleAccountSetupFormControllerProvider.notifier,
    );
    controller.initialize(
      challengeToken: widget.challengeToken,
      profilePictureUrl: widget.profilePictureUrl,
      profileName: widget.profileName,
    );

    final String initialUsername = ref.read(
      googleAccountSetupFormControllerProvider.select(
        (state) => state.username.value,
      ),
    );
    _usernameController = TextEditingController(text: initialUsername);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(
      googleAccountSetupFormControllerProvider.select(
        (state) => state.generalError,
      ),
      (String? previous, String? next) {
        if (next == null || next == previous || !context.mounted) {
          return;
        }

        context.showErrorSnackBar(next);
      },
    );

    final ThemeData theme = Theme.of(context);
    final ProfilePhoto profilePhoto = ref.watch(
      googleAccountSetupFormControllerProvider.select(
        (state) => state.profilePhoto,
      ),
    );
    final bool isSubmitting = ref.watch(
      googleAccountSetupFormControllerProvider.select(
        (state) => state.isSubmitting,
      ),
    );
    final bool canSubmit = ref.watch(
      googleAccountSetupFormControllerProvider.select(
        (state) => state.canSubmit,
      ),
    );
    final bool wasSubmitted = ref.watch(
      googleAccountSetupFormControllerProvider.select(
        (state) => state.wasSubmitted,
      ),
    );
    final app_forms.FormFieldState<String> usernameField = ref.watch(
      googleAccountSetupFormControllerProvider.select(
        (state) => state.username,
      ),
    );

    _syncControllerValue(_usernameController, usernameField.value);

    return AppFormWithBottomActions(
      body: Form(
        key: _formKey,
        autovalidateMode: wasSubmitted
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SizedBox(height: AppDimensions.spacingXl),
            const Center(child: _GoogleConnectedPill()),
            const SizedBox(height: AppDimensions.spacingLg),
            AppPageHeader(
              title: context.l10n.tr(AppLocaleKeys.authGoogleAccountSetupTitle),
              subtitle: context.l10n.tr(
                AppLocaleKeys.authGoogleAccountSetupSubtitle,
              ),
              titleStyle: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              subtitleStyle: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            const SizedBox(height: AppDimensions.spacing2xl),
            _ProfilePhotoSection(
              profilePhoto: profilePhoto,
              isSubmitting: isSubmitting,
              onPhotoChanged: ref
                  .read(googleAccountSetupFormControllerProvider.notifier)
                  .updateProfilePhoto,
              onPhotoTap: () => _handleProfilePhotoTap(profilePhoto),
            ),
            const SizedBox(height: AppDimensions.spacing2xl),
            UsernameAvailabilityField(
              controller: _usernameController,
              onChanged: ref
                  .read(googleAccountSetupFormControllerProvider.notifier)
                  .updateUsername,
              errorText: _fieldErrorText(usernameField, wasSubmitted),
              textInputAction: TextInputAction.done,
              onAvailabilityChanged: ref
                  .read(googleAccountSetupFormControllerProvider.notifier)
                  .updateUsernameAvailabilityStatus,
              onFieldSubmitted: (_) {
                if (!canSubmit) {
                  return;
                }

                unawaited(_submit());
              },
            ),
            const SizedBox(height: AppDimensions.spacing2xl),
          ],
        ),
      ),
      bottomActions: <AppFormBottomAction>[
        AppFormBottomAction(
          showWhenKeyboardOpen: true,
          child: AppButton(
            label: context.l10n.tr(AppLocaleKeys.authSignUpAction),
            onPressed: canSubmit ? _submit : null,
            isLoading: isSubmitting,
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    ref.read(googleAccountSetupFormControllerProvider.notifier).markSubmitted();

    final FormState? formState = _formKey.currentState;
    if (!(formState?.validate() ?? false)) {
      return;
    }

    await ref.read(googleAccountSetupFormControllerProvider.notifier).submit();
  }

  void _handleProfilePhotoTap(ProfilePhoto profilePhoto) {
    if (!profilePhoto.hasPhoto) {
      return;
    }

    if (profilePhoto.isNetwork) {
      AppProfileImageZoomViewer.showNetwork(
        context,
        imageUrl: profilePhoto.networkUrl!,
      );
      return;
    }

    if (profilePhoto.isLocal) {
      AppProfileImageZoomViewer.showImageProvider(
        context,
        imageProvider: FileImage(profilePhoto.localFile!),
      );
    }
  }
}

class _GoogleConnectedPill extends StatelessWidget {
  const _GoogleConnectedPill();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingMd,
          vertical: AppDimensions.spacingXs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            FaIcon(
              FontAwesomeIcons.google,
              size: 14,
              color: colorScheme.primary,
            ),
            const SizedBox(width: AppDimensions.spacingXs),
            Text(
              context.l10n.tr(
                AppLocaleKeys.authGoogleAccountSetupGoogleConnected,
              ),
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingXs),
            Icon(Icons.verified_rounded, size: 16, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }
}

class _ProfilePhotoSection extends StatelessWidget {
  const _ProfilePhotoSection({
    required this.profilePhoto,
    required this.isSubmitting,
    required this.onPhotoTap,
    required this.onPhotoChanged,
  });

  final ProfilePhoto profilePhoto;
  final bool isSubmitting;
  final VoidCallback onPhotoTap;
  final ValueChanged<ProfilePhoto> onPhotoChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        ProfilePhotoEditor(
          profilePhoto: profilePhoto,
          onPhotoChanged: onPhotoChanged,
          onPhotoTap: onPhotoTap,
          size: 124,
          badgeSize: 40,
          enabled: !isSubmitting,
          isLoading: isSubmitting,
        ),
        const SizedBox(height: AppDimensions.spacingLg),
        Text(
          context.l10n.tr(AppLocaleKeys.profilePhotoSelectPhotoTitle),
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXs),
        Text(
          context.l10n.tr(AppLocaleKeys.authGoogleAccountSetupPhotoHint),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

void _syncControllerValue(TextEditingController controller, String value) {
  if (controller.text == value) {
    return;
  }

  controller.value = controller.value.copyWith(
    text: value,
    selection: TextSelection.collapsed(offset: value.length),
    composing: TextRange.empty,
  );
}

String? _fieldErrorText(
  app_forms.FormFieldState<String> field,
  bool wasSubmitted,
) {
  if (field.error == null) {
    return null;
  }

  return field.shouldShowError || wasSubmitted ? field.error : null;
}

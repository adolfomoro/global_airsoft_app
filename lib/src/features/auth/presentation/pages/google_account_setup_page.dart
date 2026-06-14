import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:global_airsoft_app/src/app/theme/app_dimensions.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/core/logging/app_logger.dart';
import 'package:global_airsoft_app/src/core/media/profile_photo.dart';
import 'package:global_airsoft_app/src/core/network/multipart_upload_util.dart';
import 'package:global_airsoft_app/src/core/validation/backend_validation_error_mapper.dart';
import 'package:global_airsoft_app/src/core/widgets/app_bar/app_adaptive_app_bar.dart';
import 'package:global_airsoft_app/src/core/widgets/app_bar/app_page_header.dart';
import 'package:global_airsoft_app/src/core/widgets/app_snack_bar_presenter.dart';
import 'package:global_airsoft_app/src/core/widgets/form/app_button.dart';
import 'package:global_airsoft_app/src/core/widgets/image/app_profile_image_zoom_viewer.dart';
import 'package:global_airsoft_app/src/core/widgets/image/app_profile_picture_editor.dart';
import 'package:global_airsoft_app/src/core/widgets/image/profile_photo_selection_bottom_sheet.dart';
import 'package:global_airsoft_app/src/features/auth/application/services/auth_service.dart';
import 'package:global_airsoft_app/src/features/auth/data/exceptions/authentication_exception.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/dto/external_sign_up_confirm_input_dto.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/dto/google_sign_up_confirm_input_dto.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/support/auth_form_submission_mixin.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/support/auth_presentation_extensions.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/widgets/app_form_with_bottom_actions.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/widgets/username_availability_field.dart';

class _GoogleSetupProfilePhotoNotifier extends Notifier<ProfilePhoto> {
  @override
  ProfilePhoto build() {
    return const ProfilePhoto.empty();
  }

  void setNetworkPhoto(String url) {
    state = ProfilePhoto.network(url);
  }

  void setLocalPhoto(File file) {
    state = ProfilePhoto.local(file);
  }

  void clearPhoto() {
    state = const ProfilePhoto.empty();
  }
}

final _googleSetupProfilePhotoProvider =
    NotifierProvider.autoDispose<
      _GoogleSetupProfilePhotoNotifier,
      ProfilePhoto
    >(_GoogleSetupProfilePhotoNotifier.new);

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

class _GoogleAccountSetupPageState extends ConsumerState<GoogleAccountSetupPage>
    with AuthFormSubmissionMixin<GoogleAccountSetupPage> {
  static const BackendValidationErrorMapper _validationErrorMapper =
      BackendValidationErrorMapper();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController = TextEditingController(
    text: _suggestUsernameFromProfileName(widget.profileName),
  );

  bool _isLoading = false;
  String? _usernameError;
  UsernameAvailabilityStatus _usernameAvailabilityStatus =
      UsernameAvailabilityStatus.idle;

  static String _suggestUsernameFromProfileName(String profileName) {
    return profileName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '.')
        .replaceAll(RegExp(r'[^a-z0-9_.]'), '')
        .replaceAll(RegExp(r'[_.]{2,}'), '.')
        .replaceAll(RegExp(r'^[_.]+|[_.]+$'), '');
  }

  @override
  void initState() {
    super.initState();

    final String profilePictureUrl = widget.profilePictureUrl.trim();
    if (profilePictureUrl.isNotEmpty) {
      Future.microtask(() {
        ref
            .read(_googleSetupProfilePhotoProvider.notifier)
            .setNetworkPhoto(profilePictureUrl);
      });
    }
  }

  void _handleProfilePhotoTap() {
    final ProfilePhoto profilePhoto = ref.read(
      _googleSetupProfilePhotoProvider,
    );

    if (!profilePhoto.hasPhoto) return;

    if (profilePhoto.isNetwork) {
      AppProfileImageZoomViewer.showNetwork(
        context,
        imageUrl: profilePhoto.networkUrl!,
      );
    } else if (profilePhoto.isLocal) {
      AppProfileImageZoomViewer.showImageProvider(
        context,
        imageProvider: FileImage(profilePhoto.localFile!),
      );
    }
  }

  Future<void> _handleProfileEditTap() async {
    final ProfilePhoto currentPhoto = ref.read(
      _googleSetupProfilePhotoProvider,
    );

    final ProfilePhotoSelectionResult? result =
        await ProfilePhotoSelectionBottomSheet.showForResult(
          context,
          hasCurrentPhoto: currentPhoto.hasPhoto,
        );

    if (!mounted) return;
    if (result == null) return;

    if (result.hasSelectedFile) {
      ref
          .read(_googleSetupProfilePhotoProvider.notifier)
          .setLocalPhoto(result.file!);
    } else {
      ref.read(_googleSetupProfilePhotoProvider.notifier).clearPhoto();
    }
  }

  void _handleUsernameChanged(String _) {
    if (_usernameError == null) {
      return;
    }

    setState(() {
      _usernameError = null;
    });
  }

  void _handleUsernameAvailabilityChanged(UsernameAvailabilityStatus status) {
    if (_usernameAvailabilityStatus == status) {
      return;
    }

    setState(() {
      _usernameAvailabilityStatus = status;
    });
  }

  Future<void> _submitGoogleSignUp() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _usernameError = null;
    });

    if (!validateSubmittedForm(_formKey)) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final ProfilePhoto profilePhoto = ref.read(
        _googleSetupProfilePhotoProvider,
      );

      final MultipartFile? profilePictureFile =
          await _resolveProfilePictureFile(profilePhoto);

      final GoogleSignUpConfirmInputDto input = GoogleSignUpConfirmInputDto(
        challengeToken: widget.challengeToken,
        username: _usernameController.text.trim().toLowerCase(),
        profilePictureFile: profilePictureFile,
      );

      final AuthService authService = ref.read(authServiceProvider);
      await authService.signUpWithGoogle(input);
      if (!mounted) {
        return;
      }

      await ref.completeAuthenticatedSession();
    } on AuthenticationException catch (error) {
      if (!mounted) {
        return;
      }

      final ValidationMappingResult mappedErrors = _validationErrorMapper.map(
        exception: error.failure,
        targetFields: const <String>{
          ExternalSignUpConfirmInputDto.usernameField,
        },
      );

      setState(() {
        _usernameError = mappedErrors
            .fieldErrors[ExternalSignUpConfirmInputDto.usernameField];
      });

      final String? globalError = mappedErrors.firstMeaningfulGlobalError;

      final String? message = error.message ?? globalError;
      if (message != null && message.trim().isNotEmpty) {
        context.showErrorSnackBar(message, source: error.failure);
      }
    } catch (error, stackTrace) {
      AppLogger.instance.error(
        'Unexpected Google sign-up failure.',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) {
        return;
      }

      context.showLocalizedErrorSnackBar(AppLocaleKeys.authSignUpFailed);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<MultipartFile?> _resolveProfilePictureFile(
    ProfilePhoto profilePhoto,
  ) async {
    if (profilePhoto.isLocal) {
      final File localFile = profilePhoto.localFile!;
      return MultipartUploadUtil.createFromFile(localFile);
    }

    if (profilePhoto.isNetwork) {
      final String networkUrl = profilePhoto.networkUrl!;
      return MultipartUploadUtil.createFromUrl(networkUrl);
    }

    return null;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ProfilePhoto profilePhoto = ref.watch(
      _googleSetupProfilePhotoProvider,
    );
    final bool canSubmit =
        !_isLoading && !_usernameAvailabilityStatus.blocksSubmission;

    return Scaffold(
      appBar: AppAdaptiveAppBar(
        title: Text(context.l10n.tr(AppLocaleKeys.authGoogleAccountSetupTitle)),
      ),
      body: AppFormWithBottomActions(
        body: Form(
          key: _formKey,
          autovalidateMode: formAutovalidateMode,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: AppDimensions.spacingXl),
              const Center(child: _GoogleConnectedPill()),
              const SizedBox(height: AppDimensions.spacingLg),
              AppPageHeader(
                title: context.l10n.tr(
                  AppLocaleKeys.authGoogleAccountSetupTitle,
                ),
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
                onPhotoTap: _handleProfilePhotoTap,
                onEditTap: _handleProfileEditTap,
              ),
              const SizedBox(height: AppDimensions.spacing2xl),
              UsernameAvailabilityField(
                controller: _usernameController,
                onChanged: _handleUsernameChanged,
                errorText: _usernameError,
                textInputAction: TextInputAction.done,
                onAvailabilityChanged: _handleUsernameAvailabilityChanged,
                onFieldSubmitted: (_) {
                  if (!canSubmit) {
                    return;
                  }

                  unawaited(_submitGoogleSignUp());
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
              onPressed: canSubmit ? _submitGoogleSignUp : null,
              isLoading: _isLoading,
            ),
          ),
        ],
      ),
    );
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
    required this.onPhotoTap,
    required this.onEditTap,
  });

  final ProfilePhoto profilePhoto;
  final VoidCallback onPhotoTap;
  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        AppProfilePictureEditor.profilePhoto(
          profilePhoto: profilePhoto,
          size: 124,
          badgeSize: 40,
          onPhotoTap: onPhotoTap,
          onEditTap: onEditTap,
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

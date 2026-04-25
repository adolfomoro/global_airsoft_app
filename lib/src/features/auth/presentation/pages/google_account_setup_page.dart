import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/app/widgets/app_adaptive_app_bar.dart';
import 'package:global_airsoft_app/src/app/widgets/app_button.dart';
import 'package:global_airsoft_app/src/app/widgets/app_form_with_bottom_actions.dart';
import 'package:global_airsoft_app/src/app/widgets/app_text_field.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_providers.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/core/logging/app_logger.dart';
import 'package:global_airsoft_app/src/core/media/profile_photo.dart';
import 'package:global_airsoft_app/src/core/validation/backend_validation_error_mapper.dart';
import 'package:global_airsoft_app/src/core/validation/validation.dart';
import 'package:global_airsoft_app/src/core/widgets/app_profile_image_zoom_viewer.dart';
import 'package:global_airsoft_app/src/core/widgets/app_profile_picture_editor.dart';
import 'package:global_airsoft_app/src/core/widgets/profile_photo_selection_bottom_sheet.dart';
import 'package:global_airsoft_app/src/features/auth/application/services/auth_service.dart';
import 'package:global_airsoft_app/src/features/auth/data/exceptions/authentication_exception.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/dto/external_sign_up_confirm_input_dto.dart';
import 'package:global_airsoft_app/src/features/auth/data/repositories/auth_repository/dto/google_sign_up_confirm_input_dto.dart';
import 'package:global_airsoft_app/src/features/auth/domain/validation/user_name_validation.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/models/google_account_setup_arguments.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/providers/auth_providers.dart';

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
  const GoogleAccountSetupPage({required this.arguments, super.key});

  final GoogleAccountSetupArguments arguments;

  @override
  ConsumerState<GoogleAccountSetupPage> createState() =>
      _GoogleAccountSetupPageState();
}

class _GoogleAccountSetupPageState
    extends ConsumerState<GoogleAccountSetupPage> {
  static const BackendValidationErrorMapper _validationErrorMapper =
      BackendValidationErrorMapper();
  static final ValidationRuleSet _usernameValidationRules =
      UsernameValidation.rules;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _profileNameController =
      TextEditingController(text: widget.arguments.profileName);

  bool _isLoading = false;
  String? _usernameError;

  @override
  void initState() {
    super.initState();

    final String profilePictureUrl = widget.arguments.profilePictureUrl.trim();
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

    final Object? result = await ProfilePhotoSelectionBottomSheet.show(
      context,
      hasCurrentPhoto: currentPhoto.hasPhoto,
    );

    if (!mounted) return;
    if (result == null) return;

    if (result is File) {
      ref.read(_googleSetupProfilePhotoProvider.notifier).setLocalPhoto(result);
    } else {
      ref.read(_googleSetupProfilePhotoProvider.notifier).clearPhoto();
    }
  }

  String? _validateUsername(String? value) {
    if (_usernameError != null) {
      return _usernameError;
    }

    final String normalizedValue = (value ?? '').trim().toLowerCase();
    if (normalizedValue.isEmpty) {
      return null;
    }

    final ValidationFailure? failure = _usernameValidationRules.validate(
      normalizedValue,
    );
    if (failure != null) {
      return context.l10n.trArgs(failure.messageKey, args: failure.arguments);
    }

    return null;
  }

  Future<void> _handleGoogleSignUp() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _usernameError = null;
    });

    final FormState? formState = _formKey.currentState;
    if (!(formState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final ProfilePhoto profilePhoto = ref.read(
        _googleSetupProfilePhotoProvider,
      );

      final GoogleSignUpConfirmInputDto input = GoogleSignUpConfirmInputDto(
        challengeToken: widget.arguments.challengeToken,
        username: _profileNameController.text.trim().toLowerCase(),
        profilePictureFile: profilePhoto.isLocal
            ? profilePhoto.localFile
            : null,
      );

      final AuthService authService = ref.read(authServiceProvider);
      await authService.signUpWithGoogle(input);
      await ref
          .read(appLocaleControllerProvider.notifier)
          .forceApplyServerLocaleIfPending();

      if (!mounted) {
        return;
      }

      ref.read(isAuthenticatedProvider.notifier).setAuthenticated();
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

      final String? globalError = mappedErrors.globalErrors
          .where((String e) => e.trim().isNotEmpty)
          .cast<String?>()
          .firstWhere((String? e) => e != null, orElse: () => null);

      final String? message = error.message ?? globalError;
      if (message != null && message.trim().isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.tr(AppLocaleKeys.authSignUpFailed)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _profileNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ProfilePhoto profilePhoto = ref.watch(
      _googleSetupProfilePhotoProvider,
    );

    final bool canSubmit =
        !_isLoading && _profileNameController.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppAdaptiveAppBar(
        title: Text(context.l10n.tr(AppLocaleKeys.authGoogleAccountSetupTitle)),
      ),
      body: AppFormWithBottomActions(
        body: Form(
          key: _formKey,
          child: Column(
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
                child: AppProfilePictureEditor.profilePhoto(
                  profilePhoto: profilePhoto,
                  onPhotoTap: _handleProfilePhotoTap,
                  onEditTap: _handleProfileEditTap,
                ),
              ),
              const SizedBox(height: 50),
              AppTextField(
                labelText: context.l10n.tr(AppLocaleKeys.authUsernameLabel),
                controller: _profileNameController,
                validator: _validateUsername,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
        bottomActions: <AppFormBottomAction>[
          AppFormBottomAction(
            child: AppButton(
              label: context.l10n.tr(AppLocaleKeys.authSignUpAction),
              onPressed: canSubmit ? _handleGoogleSignUp : null,
              isLoading: _isLoading,
            ),
          ),
        ],
      ),
    );
  }
}

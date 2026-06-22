import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/app/theme/app_dimensions.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/core/localization/app_validation_localizations.dart';
import 'package:global_airsoft_app/src/core/validation/backend_validation_error_mapper.dart';
import 'package:global_airsoft_app/src/core/validation/full_name_validation.dart';
import 'package:global_airsoft_app/src/core/widgets/app_bar/app_adaptive_app_bar.dart';
import 'package:global_airsoft_app/src/core/widgets/app_bar/app_page_header.dart';
import 'package:global_airsoft_app/src/core/widgets/app_leave_confirmation_guard.dart';
import 'package:global_airsoft_app/src/core/widgets/app_skeleton.dart';
import 'package:global_airsoft_app/src/core/widgets/app_snack_bar_presenter.dart';
import 'package:global_airsoft_app/src/core/widgets/form/app_button.dart';
import 'package:global_airsoft_app/src/core/widgets/form/app_text_field.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/widgets/app_form_with_bottom_actions.dart';
import 'package:global_airsoft_app/src/features/users/application/providers/current_user_profile_providers.dart';
import 'package:global_airsoft_app/src/features/users/data/exceptions/user_profile_exception.dart';
import 'package:global_airsoft_app/src/features/users/data/repositories/user_profile_repository/dto/update_user_profile_input_dto.dart';
import 'package:global_airsoft_app/src/features/users/domain/models/user_profile.dart';
import 'package:global_airsoft_app/src/features/users/domain/validation/user_profile_bio_validation.dart';

class UserProfileEditPage extends ConsumerStatefulWidget {
  const UserProfileEditPage({super.key});

  @override
  ConsumerState<UserProfileEditPage> createState() =>
      _UserProfileEditPageState();
}

class _UserProfileEditPageState extends ConsumerState<UserProfileEditPage> {
  static const BackendValidationErrorMapper _validationErrorMapper =
      BackendValidationErrorMapper();
  static final _fullNameValidationRules = FullNameValidation.rules;
  static final _bioValidationRules = UserProfileBioValidation.rules;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final AppLeaveConfirmationController _leaveConfirmationController =
      AppLeaveConfirmationController();

  bool _didInitializeFields = false;
  bool _hasSubmitted = false;
  bool _isSaving = false;
  String? _fullNameError;
  String? _bioError;
  String _initialFullName = '';
  String _initialBio = '';

  String get _normalizedFullName => _fullNameController.text.trim();
  String get _normalizedBio => _bioController.text.trim();
  bool get _hasChanges =>
      _didInitializeFields &&
      (_normalizedFullName != _initialFullName ||
          _normalizedBio != _initialBio);

  @override
  void dispose() {
    _fullNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _handleRetry() async {
    ref.invalidate(currentUserProfileProvider);
  }

  void _initializeFields(UserProfile profile) {
    if (_didInitializeFields) {
      return;
    }

    _initialFullName = profile.fullName.trim();
    _initialBio = profile.bio.trim();
    _fullNameController.text = _initialFullName;
    _bioController.text = _initialBio;
    _didInitializeFields = true;
  }

  void _handleFieldChanged() {
    if (_fullNameError == null && _bioError == null) {
      setState(() {});
      return;
    }

    setState(() {
      _fullNameError = null;
      _bioError = null;
    });
  }

  bool _validateForm() {
    if (!_hasSubmitted) {
      setState(() {
        _hasSubmitted = true;
      });
    }

    return _formKey.currentState?.validate() ?? false;
  }

  Future<void> _handleCancelTap() async {
    await _leaveConfirmationController.dismiss(context);
  }

  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _fullNameError = null;
      _bioError = null;
    });

    if (_isSaving || !_hasChanges || !_validateForm()) {
      return;
    }

    final String fullName = _normalizedFullName;
    final String bio = _normalizedBio;

    setState(() {
      _isSaving = true;
    });

    try {
      await ref
          .read(userProfileServiceProvider)
          .updateCurrentUserProfile(fullName: fullName, bio: bio);
      ref.read(currentUserProfileRefreshRequestProvider.notifier).requestRefresh();

      _initialFullName = fullName;
      _initialBio = bio;

      if (!mounted) {
        return;
      }

      context.showSuccessSnackBar(
        context.l10n.tr(AppLocaleKeys.homeProfileEditUpdateSuccessMessage),
      );
      Navigator.of(context).pop();
    } on UserProfileException catch (error) {
      if (!mounted) {
        return;
      }

      final ValidationMappingResult mappedErrors = _validationErrorMapper.map(
        exception: error.failure,
        targetFields: const <String>{
          UpdateUserProfileInputDto.fullNameField,
          UpdateUserProfileInputDto.bioField,
        },
      );

      setState(() {
        _fullNameError =
            mappedErrors.fieldErrors[UpdateUserProfileInputDto.fullNameField];
        _bioError = mappedErrors.fieldErrors[UpdateUserProfileInputDto.bioField];
      });

      String? globalError;
      for (final String value in mappedErrors.globalErrors) {
        final String normalized = value.trim();
        if (normalized.isNotEmpty) {
          globalError = normalized;
          break;
        }
      }
      final String message =
          globalError ??
          error.message ??
          context.l10n.tr(AppLocaleKeys.homeProfileEditUpdateFailedMessage);
      context.showErrorSnackBar(message, source: error.failure);
    } catch (error) {
      if (!mounted) {
        return;
      }

      context.showErrorSnackBar(
        context.l10n.tr(AppLocaleKeys.homeProfileEditUpdateFailedMessage),
        source: error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<UserProfile> profileState = ref.watch(
      currentUserProfileProvider,
    );

    return Scaffold(
      appBar: AppAdaptiveAppBar(
        title: Text(context.l10n.tr(AppLocaleKeys.homeProfileEditTitle)),
        leading: IconButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).maybePop(),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        automaticallyImplyLeading: false,
      ),
      body: profileState.when(
        data: (UserProfile profile) {
          _initializeFields(profile);

          return AppLeaveConfirmationGuard(
            controller: _leaveConfirmationController,
            hasUnsavedChanges: _hasChanges,
            child: Form(
              key: _formKey,
              autovalidateMode: _hasSubmitted
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
              child: AppFormWithBottomActions(
                body: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppDimensions.maxContentWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const SizedBox(height: AppDimensions.spacingXl),
                        AppPageHeader(
                          title: context.l10n.tr(
                            AppLocaleKeys.homeProfileEditTitle,
                          ),
                          subtitle: context.l10n.tr(
                            AppLocaleKeys.homeProfileEditDescription,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spacing2xl),
                        AppTextField(
                          labelText: context.l10n.tr(
                            AppLocaleKeys.authFullNameLabel,
                          ),
                          controller: _fullNameController,
                          errorText: _fullNameError,
                          isRequired: _fullNameValidationRules.hasRequiredRule,
                          keyboardType: TextInputType.name,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          validator: _fullNameValidationRules.asValidator(
                            context.resolveValidationMessage,
                          ),
                          onChanged: (_) => _handleFieldChanged(),
                        ),
                        const SizedBox(height: AppDimensions.spacingLg),
                        AppTextField(
                          labelText: context.l10n.tr(
                            AppLocaleKeys.homeProfileBioLabel,
                          ),
                          controller: _bioController,
                          errorText: _bioError,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          textCapitalization: TextCapitalization.sentences,
                          minLines: 4,
                          maxLines: 6,
                          maxLength: UserProfileBioValidation.maxLength,
                          validator: _bioValidationRules.asValidator(
                            context.resolveValidationMessage,
                          ),
                          onChanged: (_) => _handleFieldChanged(),
                        ),
                        const SizedBox(height: AppDimensions.spacing2xl),
                      ],
                    ),
                  ),
                ),
                bottomActions: <AppFormBottomAction>[
                  AppFormBottomAction(
                    showWhenKeyboardOpen: true,
                    child: _ConstrainedBottomAction(
                      child: AppButton(
                        label: context.l10n.tr(
                          AppLocaleKeys.homeProfileEditSaveAction,
                        ),
                        isLoading: _isSaving,
                        onPressed: _isSaving || !_hasChanges
                            ? null
                            : _handleSave,
                      ),
                    ),
                  ),
                  AppFormBottomAction(
                    child: const SizedBox(height: AppDimensions.spacingSm),
                  ),
                  AppFormBottomAction(
                    showWhenKeyboardOpen: false,
                    child: _ConstrainedBottomAction(
                      child: AppButton(
                        label: context.l10n.tr(
                          AppLocaleKeys.homeProfileEditCancelAction,
                        ),
                        variant: AppButtonVariant.secondary,
                        onPressed: _isSaving ? null : _handleCancelTap,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const _UserProfileEditLoadingState(),
        error: (Object error, StackTrace stackTrace) {
          return _UserProfileEditErrorState(onRetry: _handleRetry);
        },
      ),
    );
  }
}

class _ConstrainedBottomAction extends StatelessWidget {
  const _ConstrainedBottomAction({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppDimensions.maxContentWidth,
        ),
        child: child,
      ),
    );
  }
}

class _UserProfileEditLoadingState extends StatelessWidget {
  const _UserProfileEditLoadingState();

  @override
  Widget build(BuildContext context) {
    return AppFormWithBottomActions(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppDimensions.maxContentWidth,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const <Widget>[
              SizedBox(height: AppDimensions.spacingXl),
              AppSkeleton(width: 220, height: 32),
              SizedBox(height: AppDimensions.spacingSm),
              AppSkeleton(height: 18),
              SizedBox(height: AppDimensions.spacingXs),
              AppSkeleton(width: 260, height: 18),
              SizedBox(height: AppDimensions.spacing2xl),
              AppSkeleton(height: 72),
              SizedBox(height: AppDimensions.spacingLg),
              AppSkeleton(height: 144),
            ],
          ),
        ),
      ),
      bottomActions: const <AppFormBottomAction>[
        AppFormBottomAction(
          child: _ConstrainedBottomAction(child: AppSkeleton(height: 48)),
        ),
        AppFormBottomAction(
          child: SizedBox(height: AppDimensions.spacingSm),
        ),
        AppFormBottomAction(
          child: _ConstrainedBottomAction(child: AppSkeleton(height: 48)),
        ),
      ],
    );
  }
}

class _UserProfileEditErrorState extends StatelessWidget {
  const _UserProfileEditErrorState({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppDimensions.maxContentWidth,
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.spacing2xl,
            120,
            AppDimensions.spacing2xl,
            AppDimensions.spacing2xl,
          ),
          children: <Widget>[
            Icon(
              Icons.person_off_rounded,
              size: 42,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppDimensions.spacingLg),
            Text(
              context.l10n.tr(AppLocaleKeys.homeProfileEditLoadFailedMessage),
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacingLg),
            AppButton(
              label: context.l10n.tr(AppLocaleKeys.homeProfileEditRetryAction),
              variant: AppButtonVariant.secondary,
              onPressed: onRetry,
              fullWidth: false,
            ),
          ],
        ),
      ),
    );
  }
}

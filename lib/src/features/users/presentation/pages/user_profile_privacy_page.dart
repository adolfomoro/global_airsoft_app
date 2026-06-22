import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/app/theme/app_dimensions.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/core/widgets/app_bar/app_adaptive_app_bar.dart';
import 'package:global_airsoft_app/src/core/widgets/app_leave_confirmation_guard.dart';
import 'package:global_airsoft_app/src/core/widgets/app_section_box.dart';
import 'package:global_airsoft_app/src/core/widgets/app_settings_row.dart';
import 'package:global_airsoft_app/src/core/widgets/app_skeleton.dart';
import 'package:global_airsoft_app/src/core/widgets/app_snack_bar_presenter.dart';
import 'package:global_airsoft_app/src/core/widgets/form/app_button.dart';
import 'package:global_airsoft_app/src/core/widgets/form/app_form_padding.dart';
import 'package:global_airsoft_app/src/features/users/application/providers/user_account_providers.dart';
import 'package:global_airsoft_app/src/features/users/data/exceptions/user_profile_exception.dart';
import 'package:global_airsoft_app/src/features/users/domain/models/user_profile_privacy_settings.dart';

class UserProfilePrivacyPage extends ConsumerStatefulWidget {
  const UserProfilePrivacyPage({super.key});

  @override
  ConsumerState<UserProfilePrivacyPage> createState() =>
      _UserProfilePrivacyPageState();
}

class _UserProfilePrivacyPageState
    extends ConsumerState<UserProfilePrivacyPage> {
  bool? _fullNameVisible;
  bool _isSaving = false;

  Future<void> _handleRetry() async {
    ref.invalidate(currentUserPrivacySettingsProvider);
  }

  Future<void> _handleSave(UserProfilePrivacySettings remoteSettings) async {
    final bool fullNameVisible =
        _fullNameVisible ?? remoteSettings.fullNameVisible;
    if (_isSaving || fullNameVisible == remoteSettings.fullNameVisible) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await ref
          .read(userProfileServiceProvider)
          .updateCurrentUserPrivacySettings(
            UserProfilePrivacySettings(fullNameVisible: fullNameVisible),
          );
      ref.invalidate(currentUserPrivacySettingsProvider);
      ref
          .read(currentUserProfileRefreshRequestProvider.notifier)
          .requestRefresh();

      if (!mounted) {
        return;
      }

      context.showSuccessSnackBar(
        context.l10n.tr(AppLocaleKeys.homePrivacyUpdateSuccessMessage),
      );
      Navigator.of(context).pop();
    } on UserProfileException catch (error) {
      if (!mounted) {
        return;
      }

      context.showErrorSnackBar(
        error.message ??
            context.l10n.tr(AppLocaleKeys.homePrivacyUpdateFailedMessage),
        source: error.failure,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      context.showErrorSnackBar(
        context.l10n.tr(AppLocaleKeys.homePrivacyUpdateFailedMessage),
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
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final AsyncValue<UserProfilePrivacySettings> privacyState = ref.watch(
      currentUserPrivacySettingsProvider,
    );

    return Scaffold(
      appBar: AppAdaptiveAppBar(
        title: Text(context.l10n.tr(AppLocaleKeys.homePrivacyTitle)),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppDimensions.maxContentWidth,
            ),
            child: privacyState.when(
              data: (UserProfilePrivacySettings settings) {
                final bool fullNameVisible =
                    _fullNameVisible ?? settings.fullNameVisible;
                final bool fullNamePrivate = !fullNameVisible;

                return AppLeaveConfirmationGuard(
                  hasUnsavedChanges:
                      fullNameVisible != settings.fullNameVisible,
                  child: ListView(
                    padding: AppFormPadding.standardScrollablePagePadding,
                    children: <Widget>[
                      Text(
                        context.l10n.tr(AppLocaleKeys.homePrivacyDescription),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingLg),
                      AppSectionBox(
                        title: context.l10n.tr(
                          AppLocaleKeys.homeProfileTabLabel,
                        ),
                        child: AppSettingsRow(
                          title: context.l10n.tr(
                            AppLocaleKeys.homePrivacyFullNamePrivateTitle,
                          ),
                          subtitle: context.l10n.tr(
                            AppLocaleKeys.homePrivacyFullNamePrivateDescription,
                          ),
                          enabled: !_isSaving,
                          onTap: _isSaving
                              ? null
                              : () {
                                  setState(() {
                                    _fullNameVisible = fullNamePrivate;
                                  });
                                },
                          trailing: Switch.adaptive(
                            value: fullNamePrivate,
                            onChanged: _isSaving
                                ? null
                                : (bool value) {
                                    setState(() {
                                      _fullNameVisible = !value;
                                    });
                                  },
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingLg),
                      AppButton(
                        label: context.l10n.tr(
                          AppLocaleKeys.homePrivacySaveAction,
                        ),
                        isLoading: _isSaving,
                        onPressed:
                            _isSaving ||
                                fullNameVisible == settings.fullNameVisible
                            ? null
                            : () => _handleSave(settings),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const _PrivacyLoadingState(),
              error: (Object error, StackTrace stackTrace) {
                final String message = error is UserProfileException
                    ? error.message ??
                          context.l10n.tr(
                            AppLocaleKeys.homePrivacyLoadFailedMessage,
                          )
                    : context.l10n.tr(
                        AppLocaleKeys.homePrivacyLoadFailedMessage,
                      );

                return _PrivacyErrorState(
                  message: message,
                  onRetry: _handleRetry,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _PrivacyLoadingState extends StatelessWidget {
  const _PrivacyLoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppFormPadding.standardScrollablePagePadding,
      children: const <Widget>[
        AppSkeleton(height: 18),
        SizedBox(height: AppDimensions.spacingSm),
        AppSkeleton(width: 260, height: 18),
        SizedBox(height: AppDimensions.spacingLg),
        AppSkeleton(width: 72, height: 18),
        SizedBox(height: AppDimensions.spacingSm),
        AppSkeleton(height: 104),
        SizedBox(height: AppDimensions.spacingLg),
        AppSkeleton(height: 48),
      ],
    );
  }
}

class _PrivacyErrorState extends StatelessWidget {
  const _PrivacyErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.spacing2xl,
        120,
        AppDimensions.spacing2xl,
        AppDimensions.spacing2xl,
      ),
      children: <Widget>[
        Icon(
          Icons.privacy_tip_outlined,
          size: 42,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: AppDimensions.spacingLg),
        Text(
          message,
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.spacingLg),
        AppButton(
          label: context.l10n.tr(AppLocaleKeys.homePrivacyRetryAction),
          variant: AppButtonVariant.secondary,
          onPressed: onRetry,
          fullWidth: false,
        ),
      ],
    );
  }
}

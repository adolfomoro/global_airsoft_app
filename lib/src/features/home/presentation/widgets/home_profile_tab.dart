import 'package:flutter/material.dart';
import 'package:global_airsoft_app/src/app/theme/app_colors.dart';
import 'package:global_airsoft_app/src/app/theme/app_dimensions.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/core/widgets/form/app_button.dart';
import 'package:global_airsoft_app/src/core/widgets/image/app_profile_picture_editor.dart';
import 'package:global_airsoft_app/src/features/home/presentation/view_data/home_profile_view_data.dart';

class HomeProfileTab extends StatelessWidget {
  const HomeProfileTab({
    required this.profile,
    required this.isLogoutLoading,
    required this.onLogoutPressed,
    super.key,
  });

  final HomeProfileViewData profile;
  final bool isLogoutLoading;
  final VoidCallback onLogoutPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.spacingLg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppDimensions.maxContentWidth,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacing2xl),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      colorScheme.primaryContainer,
                      colorScheme.surfaceContainerLow,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.7),
                  ),
                ),
                child: Column(
                  children: <Widget>[
                    AppProfilePictureEditor.profilePhoto(
                      profilePhoto: profile.profilePhoto,
                      size: 110,
                      badgeSize: 0,
                      showEditBadge: false,
                    ),
                    const SizedBox(height: AppDimensions.spacingLg),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spacingMd,
                        vertical: AppDimensions.spacingXs,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withValues(alpha: 0.54),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusPill,
                        ),
                      ),
                      child: Text(
                        context.l10n.tr(AppLocaleKeys.homeProfilePreviewBadge),
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppColors.secondaryLight,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingLg),
                    Text(
                      profile.displayName,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDimensions.spacingXs),
                    Text(
                      '@${profile.username}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.secondaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDimensions.spacingLg),
                    Text(
                      context.l10n.tr(
                        AppLocaleKeys.homeProfilePreviewDescription,
                      ),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spacingLg),
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacingLg),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Column(
                  children: <Widget>[
                    _ProfileInfoRow(
                      label: context.l10n.tr(AppLocaleKeys.homeProfileNameLabel),
                      value: profile.displayName,
                    ),
                    Divider(
                      height: AppDimensions.spacing2xl,
                      color: colorScheme.outlineVariant.withValues(alpha: 0.8),
                    ),
                    _ProfileInfoRow(
                      label: context.l10n.tr(
                        AppLocaleKeys.homeProfileUsernameLabel,
                      ),
                      value: '@${profile.username}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spacingLg),
              AppButton(
                label: context.l10n.tr(AppLocaleKeys.homeLogoutAction),
                onPressed: isLogoutLoading ? null : onLogoutPressed,
                isLoading: isLogoutLoading,
                variant: AppButtonVariant.secondary,
                icon: Icons.logout_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.spacingLg),
        Flexible(
          child: Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

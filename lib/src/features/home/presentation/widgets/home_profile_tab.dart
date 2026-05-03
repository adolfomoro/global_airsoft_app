import 'package:flutter/material.dart';
import 'package:global_airsoft_app/src/app/theme/app_colors.dart';
import 'package:global_airsoft_app/src/app/theme/app_dimensions.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/core/widgets/image/app_profile_picture_editor.dart';
import 'package:global_airsoft_app/src/features/home/presentation/view_data/home_profile_view_data.dart';

class HomeProfileTab extends StatelessWidget {
  const HomeProfileTab({required this.profile, super.key});

  final HomeProfileViewData profile;

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
            children: <Widget>[
              const SizedBox(height: AppDimensions.spacing2xl),
              AppProfilePictureEditor.profilePhoto(
                profilePhoto: profile.profilePhoto,
                size: 124,
                badgeSize: 0,
                showEditBadge: false,
              ),
              const SizedBox(height: AppDimensions.spacingXl),
              _ProfileHeadline(
                label: context.l10n.tr(AppLocaleKeys.homeProfileUsernameLabel),
                value: '@${profile.username}',
                valueStyle: theme.textTheme.headlineSmall?.copyWith(
                  color: AppColors.secondaryLight,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingLg),
              _ProfileHeadline(
                label: context.l10n.tr(AppLocaleKeys.homeProfileFullNameLabel),
                value: profile.fullName,
                valueStyle: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppDimensions.spacing2xl),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimensions.spacingXl),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.78),
                  ),
                ),
                child: Column(
                  children: <Widget>[
                    Text(
                      context.l10n.tr(AppLocaleKeys.homeProfileBioLabel),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingMd),
                    Text(
                      profile.bio,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.5,
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spacing2xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeadline extends StatelessWidget {
  const _ProfileHeadline({
    required this.label,
    required this.value,
    required this.valueStyle,
  });

  final String label;
  final String value;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Column(
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXs),
        Text(value, style: valueStyle, textAlign: TextAlign.center),
      ],
    );
  }
}

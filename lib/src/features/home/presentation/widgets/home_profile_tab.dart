import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/app/theme/app_colors.dart';
import 'package:global_airsoft_app/src/app/theme/app_dimensions.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/core/network/api_exception.dart';
import 'package:global_airsoft_app/src/core/network/message_resolution_policy.dart';
import 'package:global_airsoft_app/src/core/widgets/app_skeleton.dart';
import 'package:global_airsoft_app/src/core/widgets/image/app_profile_image_zoom_viewer.dart';
import 'package:global_airsoft_app/src/core/widgets/image/app_profile_picture.dart';
import 'package:global_airsoft_app/src/features/users/application/providers/users_providers.dart';
import 'package:global_airsoft_app/src/features/users/data/exceptions/user_profile_exception.dart';
import 'package:global_airsoft_app/src/features/users/domain/models/user_profile.dart';

class HomeProfileTab extends ConsumerWidget {
  const HomeProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<UserProfile> profileState = ref.watch(
      currentUserProfileProvider,
    );

    return RefreshIndicator(
      onRefresh: () => ref.refresh(currentUserProfileProvider.future),
      child: profileState.when(
        data: (UserProfile profile) => _ProfileContent(profile: profile),
        loading: () => const _ProfileLoadingState(),
        error: (Object error, StackTrace stackTrace) {
          return _ProfileErrorState(message: _resolveErrorMessage(context, error));
        },
      ),
    );
  }

  String _resolveErrorMessage(BuildContext context, Object error) {
    if (error is UserProfileException) {
      return error.message ??
          context.l10n.tr(AppLocaleKeys.homeProfileLoadFailedMessage);
    }

    if (error is ApiExceptionSource) {
      return error.apiException.resolveMessage(
            overrideMessage: context.l10n.tr(
              AppLocaleKeys.homeProfileLoadFailedMessage,
            ),
            overrideBehavior: MessageOverrideBehavior.useAsFallback,
          ) ??
          context.l10n.tr(AppLocaleKeys.homeProfileLoadFailedMessage);
    }

    return context.l10n.tr(AppLocaleKeys.homeProfileLoadFailedMessage);
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final String bio = profile.resolvedBio;
    final String zoomImageUrl = profile.resolvedZoomImageUrl;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppDimensions.spacingLg),
      children: <Widget>[
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppDimensions.maxContentWidth,
            ),
            child: Column(
              children: <Widget>[
                const SizedBox(height: AppDimensions.spacing2xl),
                AppProfilePicture.profilePhoto(
                  profilePhoto: profile.profilePhoto,
                  size: 124,
                  onTap: zoomImageUrl.isNotEmpty
                      ? () => AppProfileImageZoomViewer.showNetwork(
                          context,
                          imageUrl: zoomImageUrl,
                        )
                      : null,
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
                  value: profile.resolvedFullName,
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
                        bio.isNotEmpty
                            ? bio
                            : context.l10n.tr(
                                AppLocaleKeys.homeProfileEmptyBioLabel,
                              ),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.5,
                          color: bio.isNotEmpty
                              ? colorScheme.onSurface
                              : colorScheme.onSurfaceVariant,
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
      ],
    );
  }
}

class _ProfileLoadingState extends StatelessWidget {
  const _ProfileLoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppDimensions.spacingLg),
      children: <Widget>[
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppDimensions.maxContentWidth,
            ),
            child: Column(
              children: <Widget>[
                const SizedBox(height: AppDimensions.spacing2xl),
                const AppSkeleton.circle(size: 124),
                const SizedBox(height: AppDimensions.spacingXl),
                const AppSkeleton(width: 180, height: 28),
                const SizedBox(height: AppDimensions.spacingLg),
                const AppSkeleton(width: 220, height: 24),
                const SizedBox(height: AppDimensions.spacing2xl),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppDimensions.spacingXl),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  ),
                  child: const Column(
                    children: <Widget>[
                      AppSkeleton(width: 90, height: 18),
                      SizedBox(height: AppDimensions.spacingMd),
                      AppSkeleton(height: 18),
                      SizedBox(height: AppDimensions.spacingSm),
                      AppSkeleton(height: 18),
                      SizedBox(height: AppDimensions.spacingSm),
                      AppSkeleton(width: 180, height: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileErrorState extends StatelessWidget {
  const _ProfileErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppDimensions.spacingLg),
      children: <Widget>[
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppDimensions.maxContentWidth,
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 120),
              child: Column(
                children: <Widget>[
                  Icon(
                    Icons.person_off_rounded,
                    size: 42,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: AppDimensions.spacingLg),
                  Text(
                    message,
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimensions.spacingSm),
                  Text(
                    context.l10n.tr(AppLocaleKeys.homeProfileRefreshHint),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/app/theme/app_colors.dart';
import 'package:global_airsoft_app/src/app/theme/app_dimensions.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/core/media/profile_photo.dart';
import 'package:global_airsoft_app/src/core/network/remote_image_access_exception.dart';
import 'package:global_airsoft_app/src/core/widgets/app_section_box.dart';
import 'package:global_airsoft_app/src/core/widgets/app_skeleton.dart';
import 'package:global_airsoft_app/src/core/widgets/app_snack_bar_presenter.dart';
import 'package:global_airsoft_app/src/core/widgets/image/app_profile_image_zoom_viewer.dart';
import 'package:global_airsoft_app/src/core/widgets/image/profile_photo_editor.dart';
import 'package:global_airsoft_app/src/features/users/application/providers/users_providers.dart';
import 'package:global_airsoft_app/src/features/users/data/exceptions/user_profile_exception.dart';
import 'package:global_airsoft_app/src/features/users/domain/models/user_profile.dart';
import 'package:global_airsoft_app/src/features/users/presentation/support/user_profile_presentation_error_resolver.dart';

class HomeProfileTab extends ConsumerWidget {
  const HomeProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<UserProfile> profileState = ref.watch(
      currentUserProfileProvider,
    );

    return RefreshIndicator(
      onRefresh: () async {
        try {
          await ref.read(currentUserProfileProvider.notifier).reload();
        } catch (error) {
          if (!context.mounted) {
            return;
          }

          final Object source = error is UserProfileException
              ? error.failure
              : error;
          context.showErrorSnackBar(
            resolveUserProfilePresentationErrorMessage(context, error),
            source: source,
          );
        }
      },
      child: profileState.when(
        data: (UserProfile profile) => _ProfileContent(profile: profile),
        loading: () => const _ProfileLoadingState(),
        error: (Object error, StackTrace stackTrace) {
          return _ProfileErrorState(
            message: resolveUserProfilePresentationErrorMessage(context, error),
          );
        },
      ),
    );
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
                _EditableProfilePhotoSection(profile: profile),
                const SizedBox(height: AppDimensions.spacingXl),
                _ProfileHeadline(
                  label: context.l10n.tr(
                    AppLocaleKeys.homeProfileUsernameLabel,
                  ),
                  value: '@${profile.username}',
                  valueStyle: theme.textTheme.headlineSmall?.copyWith(
                    color: AppColors.secondaryLight,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingLg),
                _ProfileHeadline(
                  label: context.l10n.tr(
                    AppLocaleKeys.homeProfileFullNameLabel,
                  ),
                  value: profile.resolvedFullName,
                  valueStyle: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacing2xl),
                AppSectionBox(
                  title: context.l10n.tr(AppLocaleKeys.homeProfileBioLabel),
                  crossAxisAlignment: CrossAxisAlignment.center,
                  titleTextAlign: TextAlign.center,
                  child: Text(
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

class _EditableProfilePhotoSection extends ConsumerStatefulWidget {
  const _EditableProfilePhotoSection({required this.profile});

  final UserProfile profile;

  @override
  ConsumerState<_EditableProfilePhotoSection> createState() =>
      _EditableProfilePhotoSectionState();
}

class _EditableProfilePhotoSectionState
    extends ConsumerState<_EditableProfilePhotoSection> {
  static const Duration _photoLoadFailureNotificationDebounce = Duration(
    seconds: 5,
  );

  ProfilePhoto? _pendingPhoto;
  String? _lastRemotePhotoLoadFailureUrl;
  DateTime? _lastRemotePhotoLoadFailureAt;
  bool _isUploading = false;

  ProfilePhoto get _displayedPhoto =>
      _pendingPhoto ?? widget.profile.profilePhoto;

  void _handlePhotoTap() {
    final ProfilePhoto displayedPhoto = _displayedPhoto;
    if (displayedPhoto.isLocal) {
      AppProfileImageZoomViewer.showImageProvider(
        context,
        imageProvider: FileImage(displayedPhoto.localFile!),
      );
      return;
    }

    final String zoomImageUrl = widget.profile.resolvedZoomImageUrl;
    if (zoomImageUrl.isEmpty) {
      return;
    }

    AppProfileImageZoomViewer.showNetwork(context, imageUrl: zoomImageUrl);
  }

  void _handleDisplayedPhotoLoadFailed(RemoteImageAccessException error) {
    if (!mounted) {
      return;
    }

    final ProfilePhoto displayedPhoto = _displayedPhoto;
    if (!displayedPhoto.isNetwork) {
      return;
    }

    final String failedUrl = displayedPhoto.networkUrl!.trim();
    if (failedUrl.isEmpty) {
      return;
    }

    final DateTime now = DateTime.now();
    final DateTime? lastFailureAt = _lastRemotePhotoLoadFailureAt;
    final bool isDuplicateFailure =
        _lastRemotePhotoLoadFailureUrl == failedUrl &&
        lastFailureAt != null &&
        now.difference(lastFailureAt) < _photoLoadFailureNotificationDebounce;
    if (isDuplicateFailure) {
      return;
    }

    _lastRemotePhotoLoadFailureUrl = failedUrl;
    _lastRemotePhotoLoadFailureAt = now;

    context.showErrorSnackBar(context.l10n.tr(error.messageKey), source: error);
  }

  Future<void> _handlePhotoChanged(ProfilePhoto photo) async {
    if (_isUploading) {
      return;
    }

    setState(() {
      _pendingPhoto = photo;
      _isUploading = true;
    });

    try {
      final userProfileService = ref.read(userProfileServiceProvider);
      if (photo.isLocal) {
        await userProfileService.uploadCurrentUserProfilePicture(
          photo.localFile!,
        );
        await ref.read(currentUserProfileProvider.notifier).reload();
      } else if (photo.isEmpty) {
        await userProfileService.deleteCurrentUserProfilePicture();
        await ref.read(currentUserProfileProvider.notifier).reload();
      } else {
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _pendingPhoto = null;
      });

      context.showSuccessSnackBar(
        context.l10n.tr(AppLocaleKeys.homeProfilePhotoUpdateSuccessMessage),
      );
    } on UserProfileException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _pendingPhoto = null;
      });

      context.showErrorSnackBar(
        error.message ??
            context.l10n.tr(AppLocaleKeys.homeProfilePhotoUpdateFailedMessage),
        source: error.failure,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _pendingPhoto = null;
      });

      context.showErrorSnackBar(
        context.l10n.tr(AppLocaleKeys.homeProfilePhotoUpdateFailedMessage),
        source: error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ProfilePhotoEditor(
          profilePhoto: _displayedPhoto,
          onPhotoTap: _handlePhotoTap,
          onPhotoChanged: _handlePhotoChanged,
          size: 124,
          badgeSize: 40,
          enabled: !_isUploading,
          allowDelete: true,
          isLoading: _isUploading,
          onImageLoadFailed: _handleDisplayedPhotoLoadFailed,
          imageLoadFailureMessageKey:
              AppLocaleKeys.profilePhotoRemoteLoadFailed,
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
                const AppSectionBox(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  child: Column(
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

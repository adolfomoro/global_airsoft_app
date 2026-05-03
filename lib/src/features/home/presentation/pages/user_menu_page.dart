import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/app/routing/app_route_paths.dart';
import 'package:global_airsoft_app/src/app/theme/app_dimensions.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/core/widgets/app_bar/app_adaptive_app_bar.dart';
import 'package:global_airsoft_app/src/core/widgets/app_confirmation_dialog.dart';
import 'package:global_airsoft_app/src/core/widgets/app_skeleton.dart';
import 'package:global_airsoft_app/src/core/widgets/app_snack_bar_presenter.dart';
import 'package:global_airsoft_app/src/core/widgets/image/app_profile_picture.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:global_airsoft_app/src/features/users/application/providers/users_providers.dart';
import 'package:global_airsoft_app/src/features/users/domain/models/user_profile.dart';

class UserMenuPage extends ConsumerStatefulWidget {
  const UserMenuPage({super.key});

  @override
  ConsumerState<UserMenuPage> createState() => _UserMenuPageState();
}

class _UserMenuPageState extends ConsumerState<UserMenuPage> {
  bool _isLoggingOut = false;

  Future<void> _handlePrivacyTap() async {
    if (_isLoggingOut) {
      return;
    }
    await Navigator.of(context).pushNamed(AppRoutePaths.userMenuPrivacy);
  }

  Future<void> _handleLogoutTap() async {
    if (_isLoggingOut) {
      return;
    }

    final bool shouldLogout = await _showLogoutConfirmationDialog();
    if (!shouldLogout || !mounted) {
      return;
    }

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await ref.read(authServiceProvider).logout();
    } catch (error) {
      if (!mounted) {
        return;
      }

      context.showErrorSnackBar(
        context.l10n.tr(AppLocaleKeys.homeLogoutErrorMessage),
        source: error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  Future<bool> _showLogoutConfirmationDialog() async {
    return AppConfirmationDialog.show(
      context: context,
      title: context.l10n.tr(AppLocaleKeys.homeLogoutConfirmTitle),
      message: context.l10n.tr(AppLocaleKeys.homeLogoutConfirmMessage),
      cancelLabel: context.l10n.tr(AppLocaleKeys.commonCancel),
      confirmLabel: context.l10n.tr(AppLocaleKeys.homeLogoutConfirmAction),
      isDestructive: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final AsyncValue<UserProfile> profileState = ref.watch(
      currentUserProfileProvider,
    );

    return Scaffold(
      appBar: AppAdaptiveAppBar(
        title: Text(context.l10n.tr(AppLocaleKeys.homeUserMenuTitle)),
        leading: IconButton(
          onPressed: _isLoggingOut
              ? null
              : () => Navigator.of(context).maybePop(),
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          icon: const Icon(Icons.close_rounded),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppDimensions.maxContentWidth,
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.spacingLg,
                AppDimensions.spacingLg,
                AppDimensions.spacingLg,
                AppDimensions.spacing2xl,
              ),
              children: <Widget>[
                Text(
                  context.l10n.tr(AppLocaleKeys.homeUserMenuDescription),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingLg),
                _UserSummaryCard(profileState: profileState),
                const SizedBox(height: AppDimensions.spacingLg),
                _MenuActionTile(
                  icon: Icons.privacy_tip_outlined,
                  title: context.l10n.tr(AppLocaleKeys.homePrivacyAction),
                  onTap: _handlePrivacyTap,
                  enabled: !_isLoggingOut,
                ),
                const SizedBox(height: AppDimensions.spacingSm),
                _MenuActionTile(
                  icon: Icons.logout_rounded,
                  title: context.l10n.tr(AppLocaleKeys.homeLogoutAction),
                  onTap: _handleLogoutTap,
                  enabled: !_isLoggingOut,
                  isDestructive: true,
                  isLoading: _isLoggingOut,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserSummaryCard extends StatelessWidget {
  const _UserSummaryCard({required this.profileState});

  final AsyncValue<UserProfile> profileState;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.56),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingLg),
        child: profileState.when(
          data: (UserProfile profile) {
            return Row(
              children: <Widget>[
                AppProfilePicture.profilePhoto(
                  profilePhoto: profile.profilePhoto,
                  size: 84,
                ),
                const SizedBox(width: AppDimensions.spacingLg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        profile.resolvedFullName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppDimensions.spacingXs),
                      Text(
                        '@${profile.username}',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const Row(
            children: <Widget>[
              AppSkeleton.circle(size: 84),
              SizedBox(width: AppDimensions.spacingLg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    AppSkeleton(width: 180, height: 22),
                    SizedBox(height: AppDimensions.spacingSm),
                    AppSkeleton(width: 120, height: 18),
                  ],
                ),
              ),
            ],
          ),
          error: (Object error, StackTrace stackTrace) {
            return Row(
              children: <Widget>[
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.surfaceContainerHighest,
                  ),
                  child: SizedBox(
                    width: 84,
                    height: 84,
                    child: Icon(
                      Icons.person_outline_rounded,
                      size: 36,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingLg),
                Expanded(
                  child: Text(
                    context.l10n.tr(AppLocaleKeys.homeProfileLoadFailedMessage),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MenuActionTile extends StatelessWidget {
  const _MenuActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.enabled = true,
    this.isDestructive = false,
    this.isLoading = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool enabled;
  final bool isDestructive;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final Color foregroundColor = !enabled
        ? colorScheme.onSurfaceVariant
        : isDestructive
        ? colorScheme.error
        : colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        child: Ink(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingLg,
            vertical: AppDimensions.spacingMd,
          ),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 28,
                child: isLoading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            foregroundColor,
                          ),
                        ),
                      )
                    : Icon(icon, color: foregroundColor, size: 22),
              ),
              const SizedBox(width: AppDimensions.spacingMd),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: foregroundColor.withValues(alpha: 0.72),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

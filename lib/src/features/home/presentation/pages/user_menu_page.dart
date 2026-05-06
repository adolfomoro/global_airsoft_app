import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/app/routing/app_route_paths.dart';
import 'package:global_airsoft_app/src/app/theme/app_dimensions.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/core/widgets/app_bar/app_adaptive_app_bar.dart';
import 'package:global_airsoft_app/src/core/widgets/app_confirmation_dialog.dart';
import 'package:global_airsoft_app/src/core/widgets/app_section.dart';
import 'package:global_airsoft_app/src/core/widgets/app_snack_bar_presenter.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:global_airsoft_app/src/features/users/application/providers/users_providers.dart';
import 'package:global_airsoft_app/src/features/users/data/exceptions/user_profile_exception.dart';
import 'package:global_airsoft_app/src/features/users/presentation/support/user_profile_presentation_error_resolver.dart';

class UserMenuPage extends ConsumerStatefulWidget {
  const UserMenuPage({super.key});

  @override
  ConsumerState<UserMenuPage> createState() => _UserMenuPageState();
}

class _UserMenuPageState extends ConsumerState<UserMenuPage> {
  bool _isNavigating = false;
  bool _isConfirmingLogout = false;
  bool _isLoggingOut = false;

  bool get _isInteractionLocked =>
      _isNavigating || _isConfirmingLogout || _isLoggingOut;

  Future<void> _handleEditProfileTap() {
    return _openMenuRoute(AppRoutePaths.userMenuProfileEdit);
  }

  Future<void> _handlePrivacyTap() {
    return _openMenuRoute(AppRoutePaths.userMenuPrivacy);
  }

  Future<void> _openMenuRoute(String routeName) async {
    if (_isInteractionLocked) {
      return;
    }

    setState(() {
      _isNavigating = true;
    });

    try {
      await Navigator.of(context).pushNamed(routeName);
      await _reloadProfileIfRequested();
    } finally {
      if (mounted) {
        setState(() {
          _isNavigating = false;
        });
      }
    }
  }

  Future<void> _reloadProfileIfRequested() async {
    if (!mounted) {
      return;
    }

    try {
      await ref
          .read(currentUserProfileProvider.notifier)
          .reloadIfRefreshRequested();
    } catch (error) {
      if (!mounted) {
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
  }

  Future<void> _handleLogoutTap() async {
    if (_isInteractionLocked) {
      return;
    }

    setState(() {
      _isConfirmingLogout = true;
    });

    final bool shouldLogout;
    try {
      shouldLogout = await _showLogoutConfirmationDialog();
    } finally {
      if (mounted) {
        setState(() {
          _isConfirmingLogout = false;
        });
      }
    }

    if (!shouldLogout || !mounted || _isLoggingOut) {
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
    return Scaffold(
      appBar: AppAdaptiveAppBar(
        title: Text(context.l10n.tr(AppLocaleKeys.homeUserMenuTitle)),
        leading: _UserMenuCloseButton(enabled: !_isInteractionLocked),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        top: false,
        child: _UserMenuContent(
          enabled: !_isInteractionLocked,
          isLoggingOut: _isLoggingOut,
          onEditProfileTap: _handleEditProfileTap,
          onPrivacyTap: _handlePrivacyTap,
          onLogoutTap: _handleLogoutTap,
        ),
      ),
    );
  }
}

class _UserMenuCloseButton extends StatelessWidget {
  const _UserMenuCloseButton({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: enabled ? () => Navigator.of(context).maybePop() : null,
      tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
      icon: const Icon(Icons.close_rounded),
    );
  }
}

class _UserMenuContent extends StatelessWidget {
  const _UserMenuContent({
    required this.enabled,
    required this.isLoggingOut,
    required this.onEditProfileTap,
    required this.onPrivacyTap,
    required this.onLogoutTap,
  });

  final bool enabled;
  final bool isLoggingOut;
  final VoidCallback onEditProfileTap;
  final VoidCallback onPrivacyTap;
  final VoidCallback onLogoutTap;

  @override
  Widget build(BuildContext context) {
    return Center(
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
            const _UserMenuDescription(),
            const SizedBox(height: AppDimensions.spacing2xl),
            _UserMenuNavigationButton(
              icon: Icons.edit_outlined,
              title: context.l10n.tr(AppLocaleKeys.homeEditProfileAction),
              enabled: enabled,
              onTap: onEditProfileTap,
            ),
            const SizedBox(height: AppDimensions.spacing2xl),
            const _UserMenuDivider(),
            const SizedBox(height: AppDimensions.spacing2xl),
            AppSection(
              title: context.l10n.tr(
                AppLocaleKeys.homeUserMenuSettingsSectionTitle,
              ),
              child: _UserMenuNavigationButton(
                icon: Icons.privacy_tip_outlined,
                title: context.l10n.tr(AppLocaleKeys.homePrivacyAction),
                enabled: enabled,
                onTap: onPrivacyTap,
              ),
            ),
            const SizedBox(height: AppDimensions.spacing2xl),
            const _UserMenuDivider(),
            const SizedBox(height: AppDimensions.spacing2xl),
            _LogoutMenuAction(
              enabled: enabled || isLoggingOut,
              isLoading: isLoggingOut,
              onTap: onLogoutTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _UserMenuDescription extends StatelessWidget {
  const _UserMenuDescription();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Text(
      context.l10n.tr(AppLocaleKeys.homeUserMenuDescription),
      style: theme.textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
        height: 1.45,
      ),
    );
  }
}

class _UserMenuNavigationButton extends StatelessWidget {
  const _UserMenuNavigationButton({
    required this.icon,
    required this.title,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final BorderRadius borderRadius = BorderRadius.circular(
      AppDimensions.radiusLg,
    );
    final Color foregroundColor = enabled
        ? colorScheme.onSurface
        : colorScheme.onSurfaceVariant;
    final Color iconColor = enabled
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;
    final Color backgroundColor = Color.alphaBlend(
      colorScheme.onSurface.withValues(alpha: 0.06),
      colorScheme.surface,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: borderRadius,
        child: Ink(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: borderRadius,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppDimensions.controlHeight,
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.spacingLg,
                    AppDimensions.spacingSm,
                    AppDimensions.spacing2xl,
                    AppDimensions.spacingSm,
                  ),
                  child: Row(
                    children: <Widget>[
                      _MenuLeadingIcon(icon: icon, color: iconColor),
                      const SizedBox(width: AppDimensions.spacingMd),
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: foregroundColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                PositionedDirectional(
                  end: 12,
                  top: 0,
                  bottom: 0,
                  child: Center(child: _MenuChevron(enabled: enabled)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoutMenuAction extends StatelessWidget {
  const _LogoutMenuAction({
    required this.enabled,
    required this.isLoading,
    required this.onTap,
  });

  final bool enabled;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final bool isDisabled = !enabled || isLoading;
    final Color foregroundColor = isDisabled
        ? colorScheme.onSurfaceVariant
        : colorScheme.error;

    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: isDisabled ? null : onTap,
        style: TextButton.styleFrom(
          foregroundColor: foregroundColor,
          disabledForegroundColor: colorScheme.onSurfaceVariant,
          minimumSize: const Size(48, 44),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingMd,
            vertical: AppDimensions.spacingSm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          ),
          tapTargetSize: MaterialTapTargetSize.padded,
          textStyle: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        icon: isLoading
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                ),
              )
            : const Icon(Icons.logout_rounded),
        label: Text(context.l10n.tr(AppLocaleKeys.homeLogoutAction)),
      ),
    );
  }
}

class _UserMenuDivider extends StatelessWidget {
  const _UserMenuDivider();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Divider(
      height: 1,
      color: colorScheme.outlineVariant.withValues(alpha: 0.42),
    );
  }
}

class _MenuLeadingIcon extends StatelessWidget {
  const _MenuLeadingIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Center(child: Icon(icon, color: color, size: 20)),
    );
  }
}

class _MenuChevron extends StatelessWidget {
  const _MenuChevron({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color color = enabled
        ? colorScheme.onSurfaceVariant
        : colorScheme.onSurfaceVariant.withValues(alpha: 0.72);

    return Icon(Icons.chevron_right_rounded, color: color, size: 30);
  }
}

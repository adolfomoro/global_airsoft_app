import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/app/routing/app_route_paths.dart';
import 'package:global_airsoft_app/src/app/theme/app_dimensions.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/core/widgets/app_bar/app_adaptive_app_bar.dart';
import 'package:global_airsoft_app/src/core/widgets/app_confirmation_dialog.dart';
import 'package:global_airsoft_app/src/core/widgets/app_section_box.dart';
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
  bool _isLoggingOut = false;

  Future<void> _handleEditProfileTap() async {
    if (_isLoggingOut) {
      return;
    }
    await Navigator.of(context).pushNamed(AppRoutePaths.userMenuProfileEdit);
    await _reloadProfileIfRequested();
  }

  Future<void> _handlePrivacyTap() async {
    if (_isLoggingOut) {
      return;
    }
    await Navigator.of(context).pushNamed(AppRoutePaths.userMenuPrivacy);
    await _reloadProfileIfRequested();
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
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXl),
                _MenuActionTile(
                  icon: Icons.edit_outlined,
                  title: context.l10n.tr(
                    AppLocaleKeys.homeEditProfileAction,
                  ),
                  onTap: _handleEditProfileTap,
                  enabled: !_isLoggingOut,
                  isHighlighted: true,
                  showsDivider: false,
                ),
                const SizedBox(height: AppDimensions.spacingLg),
                _MenuActionGroup(
                  children: <Widget>[
                    _MenuActionTile(
                      icon: Icons.privacy_tip_outlined,
                      title: context.l10n.tr(AppLocaleKeys.homePrivacyAction),
                      onTap: _handlePrivacyTap,
                      enabled: !_isLoggingOut,
                      showsDivider: false,
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacing2xl),
                Divider(
                  height: 1,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.42),
                ),
                const SizedBox(height: AppDimensions.spacingLg),
                _MenuActionTile(
                  icon: Icons.logout_rounded,
                  title: context.l10n.tr(AppLocaleKeys.homeLogoutAction),
                  onTap: _handleLogoutTap,
                  enabled: !_isLoggingOut,
                  isDestructive: true,
                  isLoading: _isLoggingOut,
                  isCompact: true,
                  showsChevron: false,
                  showsDivider: false,
                  usesMinimalStyle: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuActionGroup extends StatelessWidget {
  const _MenuActionGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppSectionBox(
      contentPadding: EdgeInsets.zero,
      child: Column(children: children),
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
    this.isCompact = false,
    this.showsChevron = true,
    this.showsDivider = true,
    this.usesMinimalStyle = false,
    this.isHighlighted = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool enabled;
  final bool isDestructive;
  final bool isLoading;
  final bool isCompact;
  final bool showsChevron;
  final bool showsDivider;
  final bool usesMinimalStyle;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final Color foregroundColor = !enabled
        ? colorScheme.onSurfaceVariant
        : isDestructive
        ? colorScheme.error
        : colorScheme.onSurface;
    final BorderRadius borderRadius = BorderRadius.circular(
      AppDimensions.radiusLg,
    );
    final EdgeInsetsGeometry padding = EdgeInsets.symmetric(
      horizontal: usesMinimalStyle
          ? AppDimensions.spacingMd
          : AppDimensions.spacingLg,
      vertical: usesMinimalStyle
          ? AppDimensions.spacingSm
          : isCompact
          ? AppDimensions.spacingSm
          : AppDimensions.spacingMd,
    );
    final Color iconContainerColor = !enabled
        ? colorScheme.surfaceContainerHighest
        : isDestructive
        ? colorScheme.errorContainer.withValues(alpha: 0.2)
        : colorScheme.surfaceContainerHighest;
    final Color tileBackgroundColor = usesMinimalStyle
        ? Colors.transparent
        : isHighlighted
        ? colorScheme.surfaceContainerLow
        : isCompact
        ? colorScheme.surfaceContainerLowest
        : Colors.transparent;
    final BoxBorder? tileBorder = usesMinimalStyle
        ? null
        : isHighlighted || isCompact
        ? Border.all(
            color: isDestructive && isCompact
                ? colorScheme.error.withValues(alpha: 0.28)
                : colorScheme.outlineVariant.withValues(
                    alpha: isHighlighted ? 0.5 : 0.5,
                  ),
          )
        : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: borderRadius,
        child: Ink(
          decoration: BoxDecoration(
            color: tileBackgroundColor,
            borderRadius: borderRadius,
            border: tileBorder,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: padding,
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    if (!usesMinimalStyle)
                      Container(
                        width: isCompact ? 30 : 36,
                        height: isCompact ? 30 : 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: iconContainerColor,
                          borderRadius: BorderRadius.circular(
                            isCompact
                                ? AppDimensions.radiusSm
                                : AppDimensions.radiusLg,
                          ),
                        ),
                        child: isLoading
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    foregroundColor,
                                  ),
                                ),
                              )
                            : Icon(
                                icon,
                                color: foregroundColor,
                                size: isCompact ? 17 : 20,
                              ),
                      ),
                    if (!usesMinimalStyle)
                      const SizedBox(width: AppDimensions.spacingMd),
                    if (usesMinimalStyle && isLoading)
                      Padding(
                        padding: const EdgeInsets.only(
                          right: AppDimensions.spacingSm,
                        ),
                        child: SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              foregroundColor,
                            ),
                          ),
                        ),
                      ),
                    Flexible(
                      child: Text(
                        title,
                        style: (isCompact
                                ? usesMinimalStyle
                                    ? theme.textTheme.labelLarge
                                    : theme.textTheme.titleSmall
                                : theme.textTheme.titleMedium)
                            ?.copyWith(
                              color: foregroundColor,
                              fontWeight: usesMinimalStyle
                                  ? FontWeight.w700
                                  : isHighlighted
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              letterSpacing: usesMinimalStyle ? 0.2 : null,
                            ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ],
                ),
              ),
              if (showsDivider)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacingLg,
                  ),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.26),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

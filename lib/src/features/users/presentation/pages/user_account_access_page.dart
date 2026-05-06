import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:global_airsoft_app/src/app/theme/app_dimensions.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/core/widgets/app_bar/app_adaptive_app_bar.dart';
import 'package:global_airsoft_app/src/core/widgets/app_section_box.dart';
import 'package:global_airsoft_app/src/core/widgets/app_skeleton.dart';
import 'package:global_airsoft_app/src/core/widgets/app_snack_bar_presenter.dart';
import 'package:global_airsoft_app/src/core/widgets/form/app_button.dart';
import 'package:global_airsoft_app/src/core/widgets/form/app_form_padding.dart';
import 'package:global_airsoft_app/src/features/users/application/providers/users_providers.dart';
import 'package:global_airsoft_app/src/features/users/data/exceptions/user_account_exception.dart';
import 'package:global_airsoft_app/src/features/users/domain/models/user_account_access_overview.dart';

class UserAccountAccessPage extends ConsumerWidget {
  const UserAccountAccessPage({super.key});

  Future<void> _handleRefresh(WidgetRef ref) async {
    ref.invalidate(currentUserAccountAccessOverviewProvider);
    await ref.read(currentUserAccountAccessOverviewProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<UserAccountAccessOverview> overviewState = ref.watch(
      currentUserAccountAccessOverviewProvider,
    );

    return Scaffold(
      appBar: AppAdaptiveAppBar(
        title: Text(context.l10n.tr(AppLocaleKeys.homeAccountAccessTitle)),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppDimensions.maxContentWidth,
            ),
            child: overviewState.when(
              data: (UserAccountAccessOverview overview) {
                return RefreshIndicator(
                  onRefresh: () => _handleRefresh(ref),
                  child: _AccountAccessContent(overview: overview),
                );
              },
              loading: () => const _AccountAccessLoadingState(),
              error: (Object error, StackTrace stackTrace) {
                return _AccountAccessErrorState(
                  message: _resolveErrorMessage(context, error),
                  onRetry: () => _handleRefresh(ref),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  String _resolveErrorMessage(BuildContext context, Object error) {
    if (error is UserAccountException) {
      return error.message ??
          context.l10n.tr(AppLocaleKeys.homeAccountAccessLoadFailedMessage);
    }

    return context.l10n.tr(AppLocaleKeys.homeAccountAccessLoadFailedMessage);
  }
}

class _AccountAccessContent extends StatelessWidget {
  const _AccountAccessContent({required this.overview});

  final UserAccountAccessOverview overview;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppFormPadding.standardScrollablePagePadding,
      children: <Widget>[
        _AccountAccessHeroCard(
          title: context.l10n.tr(AppLocaleKeys.homeAccountAccessHeroTitle),
          description: context.l10n.tr(
            AppLocaleKeys.homeAccountAccessDescription,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingLg),
        _IdentitySection(identity: overview.identity),
        const SizedBox(height: AppDimensions.spacingLg),
        _LoginMethodsSection(methods: overview.loginMethods),
        const SizedBox(height: AppDimensions.spacing2xl),
      ],
    );
  }
}

class _IdentitySection extends StatelessWidget {
  const _IdentitySection({required this.identity});

  final UserAccountIdentity identity;

  @override
  Widget build(BuildContext context) {
    return AppSectionBox(
      title: context.l10n.tr(AppLocaleKeys.homeAccountAccessIdentitySection),
      child: _SectionCardList(
        children: <Widget>[
          _AccountActionCard(
            icon: Icons.email_outlined,
            title: context.l10n.tr(AppLocaleKeys.authEmailLabel),
            value: identity.email,
            description: _emailDescription(context, identity.emailStatus),
            status: _StatusPillData.fromContactStatus(
              context: context,
              status: identity.emailStatus,
            ),
            action: _emailAction(context, identity.emailStatus),
          ),
          _AccountActionCard(
            icon: Icons.phone_outlined,
            title: context.l10n.tr(AppLocaleKeys.homeAccountAccessPhoneLabel),
            value: identity.phoneNumber,
            description: _phoneDescription(context, identity.phoneStatus),
            status: _StatusPillData.fromContactStatus(
              context: context,
              status: identity.phoneStatus,
            ),
            action: _phoneAction(context, identity.phoneStatus),
          ),
        ],
      ),
    );
  }
}

class _LoginMethodsSection extends StatelessWidget {
  const _LoginMethodsSection({required this.methods});

  final List<UserAccountLoginMethod> methods;

  @override
  Widget build(BuildContext context) {
    return AppSectionBox(
      title: context.l10n.tr(AppLocaleKeys.homeAccountAccessMethodsSection),
      child: methods.isEmpty
          ? const _EmptySectionMessage()
          : _SectionCardList(
              children: methods
                  .map((UserAccountLoginMethod method) {
                    return _AccountActionCard(
                      icon: _loginMethodIcon(method),
                      title: _loginMethodTitle(context, method),
                      description: _loginMethodDescription(context, method),
                      status: _StatusPillData.fromLoginMethod(method, context),
                      action: _loginMethodAction(context, method),
                    );
                  })
                  .toList(growable: false),
            ),
    );
  }
}

class _AccountAccessHeroCard extends StatelessWidget {
  const _AccountAccessHeroCard({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            Color.alphaBlend(
              colorScheme.primary.withValues(alpha: 0.13),
              colorScheme.surface,
            ),
            theme.cardTheme.color ?? colorScheme.surfaceContainerHigh,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.16)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingLg),
        child: Row(
          children: <Widget>[
            _RowIcon(icon: Icons.admin_panel_settings_outlined),
            const SizedBox(width: AppDimensions.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingXss),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCardList extends StatelessWidget {
  const _SectionCardList({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.spacingLg,
        AppDimensions.spacingXs,
        AppDimensions.spacingLg,
        0,
      ),
      child: Column(
        children: <Widget>[
          for (int index = 0; index < children.length; index++) ...<Widget>[
            children[index],
            if (index < children.length - 1)
              const SizedBox(height: AppDimensions.spacingMd),
          ],
        ],
      ),
    );
  }
}

class _AccountActionCard extends StatelessWidget {
  const _AccountActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.status,
    this.action,
    this.value,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? value;
  final _StatusPillData status;
  final _AccountCardAction? action;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final String displayValue = value?.trim().isNotEmpty == true
        ? value!.trim()
        : context.l10n.tr(AppLocaleKeys.homeAccountAccessEmptyValueLabel);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.34),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _RowIcon(icon: icon),
                const SizedBox(width: AppDimensions.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingXss),
                      Text(
                        description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingSm),
                _StatusPill(data: status),
              ],
            ),
            if (value != null) ...<Widget>[
              const SizedBox(height: AppDimensions.spacingMd),
              _AccountValuePill(value: displayValue),
            ],
            if (action != null) ...<Widget>[
              const SizedBox(height: AppDimensions.spacingMd),
              _AccountActionButton(action: action!),
            ],
          ],
        ),
      ),
    );
  }
}

class _AccountValuePill extends StatelessWidget {
  const _AccountValuePill({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingMd,
          vertical: AppDimensions.spacingSm,
        ),
        child: Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.2,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _AccountActionButton extends StatelessWidget {
  const _AccountActionButton({required this.action});

  final _AccountCardAction action;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: FilledButton.icon(
        onPressed: () => action.onPressed(context),
        icon: Icon(action.icon, size: 18),
        label: Text(action.label, overflow: TextOverflow.ellipsis, maxLines: 1),
        style: FilledButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.padded,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          ),
        ),
      ),
    );
  }
}

class _AccountCardAction {
  const _AccountCardAction({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final void Function(BuildContext context) onPressed;
}

class _RowIcon extends StatelessWidget {
  const _RowIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          colorScheme.primary.withValues(alpha: 0.12),
          colorScheme.surface,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      child: Icon(icon, color: colorScheme.primary, size: 19),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.data});

  final _StatusPillData data;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: data.backgroundColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingMd,
          vertical: AppDimensions.spacingXss,
        ),
        child: Text(
          data.label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: data.foregroundColor,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ),
    );
  }
}

class _StatusPillData {
  const _StatusPillData({
    required this.label,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  final String label;
  final Color foregroundColor;
  final Color backgroundColor;

  factory _StatusPillData.fromContactStatus({
    required BuildContext context,
    required UserAccountContactStatus status,
  }) {
    return switch (status) {
      UserAccountContactStatus.verified => _StatusPillData.success(
        context,
        _contactStatusLabel(context, status),
      ),
      UserAccountContactStatus.unverified => _StatusPillData.warning(
        context,
        _contactStatusLabel(context, status),
      ),
      UserAccountContactStatus.notConfigured => _StatusPillData.neutral(
        context,
        _contactStatusLabel(context, status),
      ),
      UserAccountContactStatus.unknown => _StatusPillData.neutral(
        context,
        _contactStatusLabel(context, status),
      ),
    };
  }

  factory _StatusPillData.fromLoginMethod(
    UserAccountLoginMethod method,
    BuildContext context,
  ) {
    if (method.action != null) {
      return _StatusPillData.action(
        context,
        _loginMethodActionLabel(context, method.action!),
      );
    }

    return switch (method.status) {
      UserAccountLoginMethodStatus.active => _StatusPillData.success(
        context,
        _loginMethodStatusLabel(context, method.status),
      ),
      UserAccountLoginMethodStatus.connected => _StatusPillData.success(
        context,
        _loginMethodStatusLabel(context, method.status),
      ),
      UserAccountLoginMethodStatus.notConfigured => _StatusPillData.neutral(
        context,
        _loginMethodStatusLabel(context, method.status),
      ),
      UserAccountLoginMethodStatus.notConnected => _StatusPillData.neutral(
        context,
        _loginMethodStatusLabel(context, method.status),
      ),
      UserAccountLoginMethodStatus.unknown => _StatusPillData.neutral(
        context,
        _loginMethodStatusLabel(context, method.status),
      ),
    };
  }

  factory _StatusPillData.success(BuildContext context, String label) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color foregroundColor = colorScheme.tertiary;

    return _StatusPillData(
      label: _safeLabel(context, label),
      foregroundColor: foregroundColor,
      backgroundColor: Color.alphaBlend(
        foregroundColor.withValues(alpha: 0.14),
        colorScheme.surface,
      ),
    );
  }

  factory _StatusPillData.warning(BuildContext context, String label) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color foregroundColor = colorScheme.error;

    return _StatusPillData(
      label: _safeLabel(context, label),
      foregroundColor: foregroundColor,
      backgroundColor: Color.alphaBlend(
        foregroundColor.withValues(alpha: 0.14),
        colorScheme.surface,
      ),
    );
  }

  factory _StatusPillData.action(BuildContext context, String label) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return _StatusPillData(
      label: _safeLabel(context, label),
      foregroundColor: colorScheme.primary,
      backgroundColor: Color.alphaBlend(
        colorScheme.primary.withValues(alpha: 0.14),
        colorScheme.surface,
      ),
    );
  }

  factory _StatusPillData.neutral(BuildContext context, String label) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color foregroundColor = colorScheme.onSurfaceVariant;

    return _StatusPillData(
      label: _safeLabel(context, label),
      foregroundColor: foregroundColor,
      backgroundColor: Color.alphaBlend(
        foregroundColor.withValues(alpha: 0.12),
        colorScheme.surface,
      ),
    );
  }

  static String _safeLabel(BuildContext context, String label) {
    final String normalized = label.trim();
    if (normalized.isNotEmpty) {
      return normalized;
    }

    return context.l10n.tr(AppLocaleKeys.homeAccountAccessUnknownStatusLabel);
  }
}

class _EmptySectionMessage extends StatelessWidget {
  const _EmptySectionMessage();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingLg),
      child: Text(
        context.l10n.tr(AppLocaleKeys.homeAccountAccessEmptySectionMessage),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
          height: 1.35,
        ),
      ),
    );
  }
}

class _AccountAccessLoadingState extends StatelessWidget {
  const _AccountAccessLoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppFormPadding.standardScrollablePagePadding,
      children: const <Widget>[
        AppSkeleton(height: 18),
        SizedBox(height: AppDimensions.spacingSm),
        AppSkeleton(width: 280, height: 18),
        SizedBox(height: AppDimensions.spacingLg),
        AppSkeleton(height: 186),
        SizedBox(height: AppDimensions.spacingLg),
        AppSkeleton(height: 228),
        SizedBox(height: AppDimensions.spacingLg),
        AppSkeleton(height: 168),
      ],
    );
  }
}

class _AccountAccessErrorState extends StatelessWidget {
  const _AccountAccessErrorState({
    required this.message,
    required this.onRetry,
  });

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
          Icons.manage_accounts_outlined,
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
          label: context.l10n.tr(AppLocaleKeys.homeAccountAccessRetryAction),
          variant: AppButtonVariant.secondary,
          onPressed: onRetry,
          fullWidth: false,
        ),
      ],
    );
  }
}

_AccountCardAction? _emailAction(
  BuildContext context,
  UserAccountContactStatus status,
) {
  return switch (status) {
    UserAccountContactStatus.verified => null,
    UserAccountContactStatus.unverified => _AccountCardAction(
      label: context.l10n.tr(AppLocaleKeys.homeAccountAccessVerifyEmailAction),
      icon: Icons.mark_email_read_outlined,
      onPressed: _showUnavailableActionMessage,
    ),
    UserAccountContactStatus.notConfigured => _AccountCardAction(
      label: context.l10n.tr(AppLocaleKeys.homeAccountAccessAddEmailAction),
      icon: Icons.add_rounded,
      onPressed: _showUnavailableActionMessage,
    ),
    UserAccountContactStatus.unknown => null,
  };
}

_AccountCardAction? _phoneAction(
  BuildContext context,
  UserAccountContactStatus status,
) {
  return switch (status) {
    UserAccountContactStatus.verified => null,
    UserAccountContactStatus.unverified => _AccountCardAction(
      label: context.l10n.tr(AppLocaleKeys.homeAccountAccessVerifyPhoneAction),
      icon: Icons.verified_outlined,
      onPressed: _showUnavailableActionMessage,
    ),
    UserAccountContactStatus.notConfigured => _AccountCardAction(
      label: context.l10n.tr(AppLocaleKeys.homeAccountAccessAddPhoneAction),
      icon: Icons.add_rounded,
      onPressed: _showUnavailableActionMessage,
    ),
    UserAccountContactStatus.unknown => null,
  };
}

_AccountCardAction? _loginMethodAction(
  BuildContext context,
  UserAccountLoginMethod method,
) {
  return switch (method.action) {
    UserAccountLoginMethodAction.setPassword => _AccountCardAction(
      label: context.l10n.tr(
        AppLocaleKeys.homeAccountAccessSetPasswordActionLabel,
      ),
      icon: Icons.lock_reset_rounded,
      onPressed: _showUnavailableActionMessage,
    ),
    UserAccountLoginMethodAction.connect => _AccountCardAction(
      label: _connectLoginMethodActionLabel(context, method),
      icon: Icons.add_link_rounded,
      onPressed: _showUnavailableActionMessage,
    ),
    UserAccountLoginMethodAction.unknown => null,
    null => switch (method.status) {
      UserAccountLoginMethodStatus.notConfigured
          when method.type == UserAccountLoginMethodType.password =>
        _AccountCardAction(
          label: context.l10n.tr(
            AppLocaleKeys.homeAccountAccessSetPasswordActionLabel,
          ),
          icon: Icons.lock_reset_rounded,
          onPressed: _showUnavailableActionMessage,
        ),
      UserAccountLoginMethodStatus.notConnected
          when method.type == UserAccountLoginMethodType.google ||
              method.type == UserAccountLoginMethodType.apple =>
        _AccountCardAction(
          label: _connectLoginMethodActionLabel(context, method),
          icon: Icons.add_link_rounded,
          onPressed: _showUnavailableActionMessage,
        ),
      _ => null,
    },
  };
}

void _showUnavailableActionMessage(BuildContext context) {
  context.showInfoSnackBar(
    context.l10n.tr(AppLocaleKeys.homeAccountAccessActionUnavailableMessage),
  );
}

IconData _loginMethodIcon(UserAccountLoginMethod method) {
  if (method.type == UserAccountLoginMethodType.password) {
    return Icons.password_rounded;
  }

  return switch (method.type) {
    UserAccountLoginMethodType.google => FontAwesomeIcons.google,
    UserAccountLoginMethodType.apple => FontAwesomeIcons.apple,
    UserAccountLoginMethodType.unknown => Icons.link_rounded,
    UserAccountLoginMethodType.password => Icons.password_rounded,
  };
}

String _loginMethodTitle(BuildContext context, UserAccountLoginMethod method) {
  return switch (method.type) {
    UserAccountLoginMethodType.password => context.l10n.tr(
      AppLocaleKeys.homeAccountAccessPasswordMethodLabel,
    ),
    UserAccountLoginMethodType.google => context.l10n.tr(
      AppLocaleKeys.homeAccountAccessGoogleMethodLabel,
    ),
    UserAccountLoginMethodType.apple => context.l10n.tr(
      AppLocaleKeys.homeAccountAccessAppleMethodLabel,
    ),
    UserAccountLoginMethodType.unknown => context.l10n.tr(
      AppLocaleKeys.homeAccountAccessExternalMethodLabel,
    ),
  };
}

String _emailDescription(
  BuildContext context,
  UserAccountContactStatus status,
) {
  return switch (status) {
    UserAccountContactStatus.verified => context.l10n.tr(
      AppLocaleKeys.homeAccountAccessEmailVerifiedDescription,
    ),
    UserAccountContactStatus.unverified => context.l10n.tr(
      AppLocaleKeys.homeAccountAccessEmailUnverifiedDescription,
    ),
    UserAccountContactStatus.notConfigured => context.l10n.tr(
      AppLocaleKeys.homeAccountAccessEmailNotConfiguredDescription,
    ),
    UserAccountContactStatus.unknown => context.l10n.tr(
      AppLocaleKeys.homeAccountAccessUnknownDescription,
    ),
  };
}

String _phoneDescription(
  BuildContext context,
  UserAccountContactStatus status,
) {
  return switch (status) {
    UserAccountContactStatus.verified => context.l10n.tr(
      AppLocaleKeys.homeAccountAccessPhoneVerifiedDescription,
    ),
    UserAccountContactStatus.unverified => context.l10n.tr(
      AppLocaleKeys.homeAccountAccessPhoneUnverifiedDescription,
    ),
    UserAccountContactStatus.notConfigured => context.l10n.tr(
      AppLocaleKeys.homeAccountAccessPhoneNotConfiguredDescription,
    ),
    UserAccountContactStatus.unknown => context.l10n.tr(
      AppLocaleKeys.homeAccountAccessUnknownDescription,
    ),
  };
}

String _loginMethodDescription(
  BuildContext context,
  UserAccountLoginMethod method,
) {
  if (method.action == UserAccountLoginMethodAction.setPassword) {
    return context.l10n.tr(
      AppLocaleKeys.homeAccountAccessPasswordNotConfiguredDescription,
    );
  }

  if (method.action == UserAccountLoginMethodAction.connect) {
    return _externalLoginNotConnectedDescription(context, method);
  }

  return switch (method.status) {
    UserAccountLoginMethodStatus.active => context.l10n.tr(
      AppLocaleKeys.homeAccountAccessPasswordActiveDescription,
    ),
    UserAccountLoginMethodStatus.connected =>
      _externalLoginConnectedDescription(context, method),
    UserAccountLoginMethodStatus.notConfigured => context.l10n.tr(
      AppLocaleKeys.homeAccountAccessPasswordNotConfiguredDescription,
    ),
    UserAccountLoginMethodStatus.notConnected =>
      _externalLoginNotConnectedDescription(context, method),
    UserAccountLoginMethodStatus.unknown => context.l10n.tr(
      AppLocaleKeys.homeAccountAccessUnknownDescription,
    ),
  };
}

String _externalLoginConnectedDescription(
  BuildContext context,
  UserAccountLoginMethod method,
) {
  return switch (method.type) {
    UserAccountLoginMethodType.google => context.l10n.tr(
      AppLocaleKeys.homeAccountAccessGoogleConnectedDescription,
    ),
    UserAccountLoginMethodType.apple => context.l10n.tr(
      AppLocaleKeys.homeAccountAccessAppleConnectedDescription,
    ),
    UserAccountLoginMethodType.password => context.l10n.tr(
      AppLocaleKeys.homeAccountAccessPasswordActiveDescription,
    ),
    UserAccountLoginMethodType.unknown => context.l10n.tr(
      AppLocaleKeys.homeAccountAccessExternalConnectedDescription,
    ),
  };
}

String _externalLoginNotConnectedDescription(
  BuildContext context,
  UserAccountLoginMethod method,
) {
  return switch (method.type) {
    UserAccountLoginMethodType.google => context.l10n.tr(
      AppLocaleKeys.homeAccountAccessGoogleNotConnectedDescription,
    ),
    UserAccountLoginMethodType.apple => context.l10n.tr(
      AppLocaleKeys.homeAccountAccessAppleNotConnectedDescription,
    ),
    UserAccountLoginMethodType.password => context.l10n.tr(
      AppLocaleKeys.homeAccountAccessPasswordNotConfiguredDescription,
    ),
    UserAccountLoginMethodType.unknown => context.l10n.tr(
      AppLocaleKeys.homeAccountAccessExternalNotConnectedDescription,
    ),
  };
}

String _connectLoginMethodActionLabel(
  BuildContext context,
  UserAccountLoginMethod method,
) {
  return switch (method.type) {
    UserAccountLoginMethodType.google => context.l10n.tr(
      AppLocaleKeys.homeAccountAccessConnectGoogleAction,
    ),
    UserAccountLoginMethodType.apple => context.l10n.tr(
      AppLocaleKeys.homeAccountAccessConnectAppleAction,
    ),
    UserAccountLoginMethodType.password => context.l10n.tr(
      AppLocaleKeys.homeAccountAccessSetPasswordActionLabel,
    ),
    UserAccountLoginMethodType.unknown => context.l10n.tr(
      AppLocaleKeys.homeAccountAccessConnectActionLabel,
    ),
  };
}

String _contactStatusLabel(
  BuildContext context,
  UserAccountContactStatus status,
) {
  return switch (status) {
    UserAccountContactStatus.verified => context.l10n.tr(
      AppLocaleKeys.homeAccountAccessVerifiedLabel,
    ),
    UserAccountContactStatus.unverified => context.l10n.tr(
      AppLocaleKeys.homeAccountAccessUnverifiedLabel,
    ),
    UserAccountContactStatus.notConfigured => context.l10n.tr(
      AppLocaleKeys.homeAccountAccessNotConfiguredLabel,
    ),
    UserAccountContactStatus.unknown => context.l10n.tr(
      AppLocaleKeys.homeAccountAccessUnknownStatusLabel,
    ),
  };
}

String _loginMethodStatusLabel(
  BuildContext context,
  UserAccountLoginMethodStatus status,
) {
  return switch (status) {
    UserAccountLoginMethodStatus.active => context.l10n.tr(
      AppLocaleKeys.homeAccountAccessActiveLabel,
    ),
    UserAccountLoginMethodStatus.notConfigured => context.l10n.tr(
      AppLocaleKeys.homeAccountAccessNotConfiguredLabel,
    ),
    UserAccountLoginMethodStatus.connected => context.l10n.tr(
      AppLocaleKeys.homeAccountAccessConnectedLabel,
    ),
    UserAccountLoginMethodStatus.notConnected => context.l10n.tr(
      AppLocaleKeys.homeAccountAccessNotConnectedLabel,
    ),
    UserAccountLoginMethodStatus.unknown => context.l10n.tr(
      AppLocaleKeys.homeAccountAccessUnknownStatusLabel,
    ),
  };
}

String _loginMethodActionLabel(
  BuildContext context,
  UserAccountLoginMethodAction action,
) {
  return switch (action) {
    UserAccountLoginMethodAction.setPassword => context.l10n.tr(
      AppLocaleKeys.homeAccountAccessSetPasswordActionLabel,
    ),
    UserAccountLoginMethodAction.connect => context.l10n.tr(
      AppLocaleKeys.homeAccountAccessConnectActionLabel,
    ),
    UserAccountLoginMethodAction.unknown => context.l10n.tr(
      AppLocaleKeys.homeAccountAccessUnknownStatusLabel,
    ),
  };
}

import 'package:flutter/material.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/core/widgets/app_button.dart';

class RequestNotificationPermissionScreen extends StatelessWidget {
  const RequestNotificationPermissionScreen({
    required this.onAllow,
    required this.onDismiss,
    this.mode = NotificationPermissionScreenMode.prePrompt,
    super.key,
  });

  final VoidCallback onAllow;
  final VoidCallback onDismiss;
  final NotificationPermissionScreenMode mode;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AppLocalizations l10n = context.l10n;
    final bool isOpenSettingsMode =
        mode == NotificationPermissionScreenMode.openSettings;

    final String title = isOpenSettingsMode
        ? l10n.tr(AppLocaleKeys.notificationPermissionDeniedTitle)
        : l10n.tr(AppLocaleKeys.notificationPermissionPrePromptTitle);
    final String subtitle = isOpenSettingsMode
        ? l10n.tr(AppLocaleKeys.notificationPermissionDeniedBody)
        : l10n.tr(AppLocaleKeys.notificationPermissionPrePromptSubtitle);
    final String primaryButtonLabel = isOpenSettingsMode
        ? l10n.tr(AppLocaleKeys.notificationPermissionOpenSettings)
        : l10n.tr(AppLocaleKeys.notificationPermissionAllow);
    final String dismissLabel = isOpenSettingsMode
        ? l10n.tr(AppLocaleKeys.notificationPermissionDismiss)
        : l10n.tr(AppLocaleKeys.notificationPermissionDismiss);

    return Scaffold(
      body: PopScope(
        canPop: false,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: <Widget>[
                const SizedBox(height: 24),
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Icon(
                    Icons.notifications_active_rounded,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 52,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  title,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  subtitle,
                  style: textTheme.bodyMedium?.copyWith(height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: <Widget>[
                        _BenefitItem(
                          icon: Icons.people_rounded,
                          title: l10n.tr(
                            AppLocaleKeys
                                .notificationPermissionPrePromptBenefitFriendRequestsTitle,
                          ),
                          description: l10n.tr(
                            AppLocaleKeys
                                .notificationPermissionPrePromptBenefitFriendRequestsDescription,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _BenefitItem(
                          icon: Icons.local_fire_department_rounded,
                          title: l10n.tr(
                            AppLocaleKeys
                                .notificationPermissionPrePromptBenefitGamesTitle,
                          ),
                          description: l10n.tr(
                            AppLocaleKeys
                                .notificationPermissionPrePromptBenefitGamesDescription,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _BenefitItem(
                          icon: Icons.groups_rounded,
                          title: l10n.tr(
                            AppLocaleKeys
                                .notificationPermissionPrePromptBenefitTeamsTitle,
                          ),
                          description: l10n.tr(
                            AppLocaleKeys
                                .notificationPermissionPrePromptBenefitTeamsDescription,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                AppButton(label: primaryButtonLabel, onPressed: onAllow),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onDismiss,
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant,
                  ),
                  child: Text(
                    dismissLabel,
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum NotificationPermissionScreenMode { prePrompt, openSettings }

class _BenefitItem extends StatelessWidget {
  const _BenefitItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(description, style: textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

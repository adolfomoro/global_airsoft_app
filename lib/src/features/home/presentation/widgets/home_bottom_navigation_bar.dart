import 'package:flutter/material.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/features/home/presentation/providers/home_providers.dart';

class HomeBottomNavigationBar extends StatelessWidget {
  const HomeBottomNavigationBar({
    required this.currentTab,
    required this.onDestinationSelected,
    super.key,
  });

  final HomeTab currentTab;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.34),
          ),
        ),
      ),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: colorScheme.surface,
          indicatorColor: colorScheme.primaryContainer.withValues(alpha: 0.88),
          labelTextStyle: WidgetStatePropertyAll(
            theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        child: NavigationBar(
          height: 68,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          selectedIndex: currentTab.index,
          onDestinationSelected: onDestinationSelected,
          destinations: <NavigationDestination>[
            NavigationDestination(
              icon: const Icon(Icons.explore_outlined),
              selectedIcon: const Icon(Icons.explore_rounded),
              label: context.l10n.tr(AppLocaleKeys.homeDiscoveryTabLabel),
            ),
            NavigationDestination(
              icon: const Icon(Icons.dynamic_feed_outlined),
              selectedIcon: const Icon(Icons.dynamic_feed_rounded),
              label: context.l10n.tr(AppLocaleKeys.homeTimelineTabLabel),
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline_rounded),
              selectedIcon: const Icon(Icons.person_rounded),
              label: context.l10n.tr(AppLocaleKeys.homeProfileTabLabel),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/core/widgets/app_bar/app_adaptive_app_bar.dart';
import 'package:global_airsoft_app/src/features/home/presentation/providers/home_providers.dart';
import 'package:global_airsoft_app/src/features/home/presentation/widgets/home_bottom_navigation_bar.dart';
import 'package:global_airsoft_app/src/features/home/presentation/widgets/home_placeholder_tab.dart';
import 'package:global_airsoft_app/src/features/home/presentation/widgets/home_profile_tab.dart';
import 'package:global_airsoft_app/src/features/users/application/providers/users_providers.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    ref.read(homeTabProvider.notifier).select(HomeTab.discovery);
    ref.read(currentUserProfileControllerProvider).load();
  }

  @override
  Widget build(BuildContext context) {
    final HomeTab currentTab = ref.watch(homeTabProvider);
    final homeTabNotifier = ref.read(homeTabProvider.notifier);

    return Scaffold(
      appBar: AppAdaptiveAppBar(
        title: Text(_resolveTitle(context, currentTab)),
      ),
      body: IndexedStack(
        index: currentTab.index,
        children: <Widget>[
          HomePlaceholderTab(
            icon: Icons.explore_rounded,
            title: context.l10n.tr(AppLocaleKeys.homeDiscoveryTabLabel),
            message: context.l10n.tr(
              AppLocaleKeys.homeDiscoveryPlaceholderMessage,
            ),
          ),
          HomePlaceholderTab(
            icon: Icons.dynamic_feed_rounded,
            title: context.l10n.tr(AppLocaleKeys.homeTimelineTabLabel),
            message: context.l10n.tr(
              AppLocaleKeys.homeTimelinePlaceholderMessage,
            ),
          ),
          const HomeProfileTab(),
        ],
      ),
      bottomNavigationBar: HomeBottomNavigationBar(
        currentTab: currentTab,
        onDestinationSelected: homeTabNotifier.selectIndex,
      ),
    );
  }

  String _resolveTitle(BuildContext context, HomeTab currentTab) {
    switch (currentTab) {
      case HomeTab.discovery:
        return context.l10n.tr(AppLocaleKeys.homeDiscoveryTabLabel);
      case HomeTab.timeline:
        return context.l10n.tr(AppLocaleKeys.homeTimelineTabLabel);
      case HomeTab.profile:
        return context.l10n.tr(AppLocaleKeys.homeProfileTabLabel);
    }
  }
}

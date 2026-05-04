import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/app/routing/app_route_paths.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/core/widgets/app_bar/app_adaptive_app_bar.dart';
import 'package:global_airsoft_app/src/core/widgets/app_snack_bar_presenter.dart';
import 'package:global_airsoft_app/src/features/home/presentation/providers/home_providers.dart';
import 'package:global_airsoft_app/src/features/home/presentation/widgets/home_bottom_navigation_bar.dart';
import 'package:global_airsoft_app/src/features/home/presentation/widgets/home_placeholder_tab.dart';
import 'package:global_airsoft_app/src/features/home/presentation/widgets/home_profile_tab.dart';
import 'package:global_airsoft_app/src/features/users/application/providers/users_providers.dart';
import 'package:global_airsoft_app/src/features/users/data/exceptions/user_profile_exception.dart';
import 'package:global_airsoft_app/src/features/users/presentation/support/user_profile_presentation_error_resolver.dart';

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
    ref.read(currentUserProfileRefreshRequestProvider.notifier).clear();
    ref.read(currentUserProfileProvider.future);
  }

  Future<void> _handleUserMenuTap() async {
    await Navigator.of(context).pushNamed(AppRoutePaths.userMenu);
    if (!mounted) {
      return;
    }

    await _reloadProfileIfRequested();
  }

  Future<void> _reloadProfileIfRequested() async {
    if (!ref.read(currentUserProfileRefreshRequestProvider)) {
      return;
    }

    try {
      await ref.read(currentUserProfileProvider.notifier).reload();
      ref.read(currentUserProfileRefreshRequestProvider.notifier).clear();
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

  @override
  Widget build(BuildContext context) {
    final HomeTab currentTab = ref.watch(homeTabProvider);
    final homeTabNotifier = ref.read(homeTabProvider.notifier);

    return Scaffold(
      appBar: AppAdaptiveAppBar(
        title: Text(_resolveTitle(context, currentTab)),
        actions: currentTab == HomeTab.profile
            ? <Widget>[
                IconButton(
                  onPressed: _handleUserMenuTap,
                  tooltip: context.l10n.tr(AppLocaleKeys.homeUserMenuAction),
                  icon: const Icon(Icons.menu_rounded),
                ),
              ]
            : null,
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

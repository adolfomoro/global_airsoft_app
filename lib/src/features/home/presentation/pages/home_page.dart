import 'dart:async';

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
  static const Duration _tabTransitionDuration = Duration(milliseconds: 220);

  late final PageController _pageController;
  ProviderSubscription<HomeTab>? _homeTabSubscription;

  @override
  void initState() {
    super.initState();
    ref.read(homeTabProvider.notifier).select(HomeTab.discovery);
    _pageController = PageController(
      initialPage: ref.read(homeTabProvider).index,
    );
    _homeTabSubscription = ref.listenManual<HomeTab>(homeTabProvider, (
      HomeTab? previous,
      HomeTab next,
    ) {
      if (previous == next) {
        return;
      }

      unawaited(_syncPageToTab(next));
    });
    ref.read(currentUserProfileRefreshRequestProvider.notifier).clear();
    ref.read(currentUserProfileProvider.future);
  }

  @override
  void dispose() {
    _homeTabSubscription?.close();
    _homeTabSubscription = null;
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleUserMenuTap() async {
    await Navigator.of(context).pushNamed(AppRoutePaths.userMenu);
    if (!mounted) {
      return;
    }

    await _reloadProfileIfRequested();
  }

  Future<void> _reloadProfileIfRequested() async {
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

  Future<void> _syncPageToTab(HomeTab tab) async {
    final int targetPage = tab.index;
    if (!_pageController.hasClients) {
      return;
    }

    final int currentPage =
        _pageController.page?.round() ?? _pageController.initialPage;
    if (currentPage == targetPage) {
      return;
    }

    await _pageController.animateToPage(
      targetPage,
      duration: _tabTransitionDuration,
      curve: Curves.easeOutCubic,
    );
  }

  void _handlePageChanged(int index) {
    ref.read(homeTabProvider.notifier).selectIndex(index);
  }

  void _handleDestinationSelected(int index) {
    ref.read(homeTabProvider.notifier).selectIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    final HomeTab currentTab = ref.watch(homeTabProvider);

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _handlePageChanged,
        children: <Widget>[
          _HomeDiscoveryTabPage(
            title: context.l10n.tr(AppLocaleKeys.homeDiscoveryTabLabel),
            message: context.l10n.tr(
              AppLocaleKeys.homeDiscoveryPlaceholderMessage,
            ),
          ),
          _HomeTimelineTabPage(
            title: context.l10n.tr(AppLocaleKeys.homeTimelineTabLabel),
            message: context.l10n.tr(
              AppLocaleKeys.homeTimelinePlaceholderMessage,
            ),
          ),
          _HomeProfileTabPage(onUserMenuTap: _handleUserMenuTap),
        ],
      ),
      bottomNavigationBar: HomeBottomNavigationBar(
        currentTab: currentTab,
        onDestinationSelected: _handleDestinationSelected,
      ),
    );
  }
}

class _HomeDiscoveryTabPage extends StatelessWidget {
  const _HomeDiscoveryTabPage({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return _HomeTabScaffold(
      appBar: AppAdaptiveAppBar(title: Text(title)),
      body: HomePlaceholderTab(
        icon: Icons.explore_rounded,
        title: title,
        message: message,
      ),
    );
  }
}

class _HomeTimelineTabPage extends StatelessWidget {
  const _HomeTimelineTabPage({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return _HomeTabScaffold(
      appBar: AppAdaptiveAppBar(title: Text(title)),
      body: HomePlaceholderTab(
        icon: Icons.dynamic_feed_rounded,
        title: title,
        message: message,
      ),
    );
  }
}

class _HomeProfileTabPage extends StatelessWidget {
  const _HomeProfileTabPage({required this.onUserMenuTap});

  final Future<void> Function() onUserMenuTap;

  @override
  Widget build(BuildContext context) {
    return _HomeTabScaffold(
      appBar: AppAdaptiveAppBar(
        title: Text(context.l10n.tr(AppLocaleKeys.homeProfileTabLabel)),
        actions: <Widget>[
          IconButton(
            onPressed: onUserMenuTap,
            tooltip: context.l10n.tr(AppLocaleKeys.homeUserMenuAction),
            icon: const Icon(Icons.menu_rounded),
          ),
        ],
      ),
      body: const HomeProfileTab(),
    );
  }
}

class _HomeTabScaffold extends StatelessWidget {
  const _HomeTabScaffold({required this.body, this.appBar});

  final PreferredSizeWidget? appBar;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: appBar, body: body);
  }
}

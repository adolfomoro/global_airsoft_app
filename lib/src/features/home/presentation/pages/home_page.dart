import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_keys.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/core/logging/app_logger.dart';
import 'package:global_airsoft_app/src/core/widgets/app_bar/app_adaptive_app_bar.dart';
import 'package:global_airsoft_app/src/core/widgets/app_snack_bar_presenter.dart';
import 'package:global_airsoft_app/src/features/auth/data/exceptions/authentication_exception.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:global_airsoft_app/src/features/home/presentation/providers/home_providers.dart';
import 'package:global_airsoft_app/src/features/home/presentation/widgets/home_bottom_navigation_bar.dart';
import 'package:global_airsoft_app/src/features/home/presentation/widgets/home_placeholder_tab.dart';
import 'package:global_airsoft_app/src/features/home/presentation/widgets/home_profile_tab.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _isLogoutLoading = false;

  Future<void> _submitLogout() async {
    if (_isLogoutLoading) {
      return;
    }

    setState(() {
      _isLogoutLoading = true;
    });

    try {
      await ref.read(authServiceProvider).logout();
    } catch (error, stackTrace) {
      AppLogger.instance.error(
        'Logout failed.',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) {
        return;
      }

      final String fallbackMessage = context.l10n.tr(
        AppLocaleKeys.homeLogoutErrorMessage,
      );
      final String message = error is AuthenticationException
          ? (error.message ?? fallbackMessage)
          : fallbackMessage;
      context.showErrorSnackBar(message, source: error);
    } finally {
      if (mounted) {
        setState(() {
          _isLogoutLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final HomeTab currentTab = ref.watch(homeTabProvider);
    final homeTabNotifier = ref.read(homeTabProvider.notifier);
    final profileViewData = ref.watch(homeProfileViewDataProvider);

    return Scaffold(
      appBar: AppAdaptiveAppBar(
        title: Text(_resolveTitle(context, currentTab)),
        actions: currentTab == HomeTab.profile
            ? <Widget>[
                IconButton(
                  icon: const Icon(Icons.logout_rounded),
                  onPressed: _isLogoutLoading ? null : _submitLogout,
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
          HomeProfileTab(
            profile: profileViewData,
            isLogoutLoading: _isLogoutLoading,
            onLogoutPressed: _submitLogout,
          ),
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

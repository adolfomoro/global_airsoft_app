import 'package:flutter/material.dart';
import 'package:global_airsoft_app/src/app/routing/app_route_paths.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/pages/login_page.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/pages/password_recovery_page.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/pages/password_recovery_success_page.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/pages/sign_up_page.dart';
import 'package:global_airsoft_app/src/features/home/presentation/pages/home_page.dart';

enum AppRouteAccess { public, authenticatedOnly, unauthenticatedOnly }

typedef AppRoutePageBuilder =
    Widget Function(BuildContext context, Object? arguments);

final class AppRoutes {
  AppRoutes._();

  static Route<dynamic> onGenerateRoute(
    RouteSettings settings, {
    required bool isAuthenticated,
  }) {
    final String routeName =
        settings.name ?? _defaultRouteName(isAuthenticated);
    final _AppRouteDefinition definition =
        _routes[routeName] ?? _routes[_defaultRouteName(isAuthenticated)]!;

    if (!_canAccess(definition.access, isAuthenticated)) {
      return _buildFallbackRoute(isAuthenticated);
    }

    return MaterialPageRoute<dynamic>(
      settings: RouteSettings(name: routeName, arguments: settings.arguments),
      builder: (BuildContext context) =>
          definition.builder(context, settings.arguments),
    );
  }

  static String _defaultRouteName(bool isAuthenticated) {
    return isAuthenticated ? AppRoutePaths.home : AppRoutePaths.login;
  }

  static bool _canAccess(AppRouteAccess access, bool isAuthenticated) {
    switch (access) {
      case AppRouteAccess.public:
        return true;
      case AppRouteAccess.authenticatedOnly:
        return isAuthenticated;
      case AppRouteAccess.unauthenticatedOnly:
        return !isAuthenticated;
    }
  }

  static Route<dynamic> _buildFallbackRoute(bool isAuthenticated) {
    final String fallbackRoute = _defaultRouteName(isAuthenticated);
    final _AppRouteDefinition definition = _routes[fallbackRoute]!;

    return MaterialPageRoute<dynamic>(
      settings: RouteSettings(name: fallbackRoute),
      builder: (BuildContext context) => definition.builder(context, null),
    );
  }

  static final Map<String, _AppRouteDefinition> _routes =
      <String, _AppRouteDefinition>{
        AppRoutePaths.login: _AppRouteDefinition(
          access: AppRouteAccess.unauthenticatedOnly,
          builder: (BuildContext context, Object? arguments) {
            return const LoginPage();
          },
        ),
        AppRoutePaths.signUp: _AppRouteDefinition(
          access: AppRouteAccess.unauthenticatedOnly,
          builder: (BuildContext context, Object? arguments) {
            return const SignUpPage();
          },
        ),
        AppRoutePaths.passwordRecovery: _AppRouteDefinition(
          access: AppRouteAccess.unauthenticatedOnly,
          builder: (BuildContext context, Object? arguments) {
            return const PasswordRecoveryPage();
          },
        ),
        AppRoutePaths.passwordRecoverySuccess: _AppRouteDefinition(
          access: AppRouteAccess.unauthenticatedOnly,
          builder: (BuildContext context, Object? arguments) {
            final String email = arguments is String ? arguments : '';
            if (email.trim().isEmpty) {
              return const PasswordRecoveryPage();
            }

            return PasswordRecoverySuccessPage(email: email);
          },
        ),
        AppRoutePaths.home: _AppRouteDefinition(
          access: AppRouteAccess.authenticatedOnly,
          builder: (BuildContext context, Object? arguments) {
            return const HomePage();
          },
        ),
      };
}

final class _AppRouteDefinition {
  const _AppRouteDefinition({required this.access, required this.builder});

  final AppRouteAccess access;
  final AppRoutePageBuilder builder;
}

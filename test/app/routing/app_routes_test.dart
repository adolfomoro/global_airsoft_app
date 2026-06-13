import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_airsoft_app/src/app/routing/app_route_paths.dart';
import 'package:global_airsoft_app/src/app/routing/app_routes.dart';

void main() {
  test('uses the latest auth state when generating protected routes', () {
    bool isAuthenticated = false;

    final Route<dynamic> unauthenticatedHomeRoute = AppRoutes.onGenerateRoute(
      const RouteSettings(name: AppRoutePaths.home),
      isAuthenticated: () => isAuthenticated,
    );

    expect(unauthenticatedHomeRoute.settings.name, AppRoutePaths.login);

    isAuthenticated = true;

    final Route<dynamic> authenticatedHomeRoute = AppRoutes.onGenerateRoute(
      const RouteSettings(name: AppRoutePaths.home),
      isAuthenticated: () => isAuthenticated,
    );

    expect(authenticatedHomeRoute.settings.name, AppRoutePaths.home);
  });

  test('redirects unauthenticated routes to home when already signed in', () {
    final bool isAuthenticated = true;

    final Route<dynamic> loginRoute = AppRoutes.onGenerateRoute(
      const RouteSettings(name: AppRoutePaths.login),
      isAuthenticated: () => isAuthenticated,
    );

    expect(loginRoute.settings.name, AppRoutePaths.home);
  });

  test('maps the google account setup route for unauthenticated users', () {
    final bool isAuthenticated = false;

    final Route<dynamic> route = AppRoutes.onGenerateRoute(
      const RouteSettings(name: AppRoutePaths.googleAccountSetup),
      isAuthenticated: () => isAuthenticated,
    );

    expect(route.settings.name, AppRoutePaths.googleAccountSetup);
  });

  test('maps the privacy route for authenticated users', () {
    final bool isAuthenticated = true;

    final Route<dynamic> route = AppRoutes.onGenerateRoute(
      const RouteSettings(name: AppRoutePaths.userMenuPrivacy),
      isAuthenticated: () => isAuthenticated,
    );

    expect(route.settings.name, AppRoutePaths.userMenuPrivacy);
  });

  test('maps the profile edit route for authenticated users', () {
    final bool isAuthenticated = true;

    final Route<dynamic> route = AppRoutes.onGenerateRoute(
      const RouteSettings(name: AppRoutePaths.userMenuProfileEdit),
      isAuthenticated: () => isAuthenticated,
    );

    expect(route.settings.name, AppRoutePaths.userMenuProfileEdit);
  });

  test('generates a single initial route without expanding the stack', () {
    final bool isAuthenticated = false;

    final List<Route<dynamic>> routes = AppRoutes.onGenerateInitialRoutes(
      AppRoutePaths.login,
      isAuthenticated: () => isAuthenticated,
    );

    expect(routes, hasLength(1));
    expect(routes.single.settings.name, AppRoutePaths.login);
  });
}

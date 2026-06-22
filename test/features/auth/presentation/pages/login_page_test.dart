import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_airsoft_app/src/app/routing/app_route_paths.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/pages/login_page.dart';

void main() {
  Future<void> pumpLoginPage(
    WidgetTester tester, {
    Widget? home,
    Map<String, WidgetBuilder> routes = const <String, WidgetBuilder>{},
  }) {
    return tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          routes: routes,
          home: home ?? const LoginPage(),
        ),
      ),
    );
  }

  testWidgets('LoginPage renders key presentation actions', (
    WidgetTester tester,
  ) async {
    await pumpLoginPage(tester);
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.text('Global Airsoft App'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });

  testWidgets('LoginPage keeps typed credentials in the visible fields', (
    WidgetTester tester,
  ) async {
    await pumpLoginPage(tester);
    await tester.pumpAndSettle();

    final textFields = find.byType(TextFormField);

    await tester.enterText(textFields.at(0), 'player@example.com');
    await tester.enterText(textFields.at(1), 'Secret123!');
    await tester.pump();

    expect(
      tester.widget<TextFormField>(textFields.at(0)).controller?.text,
      'player@example.com',
    );
    expect(
      tester.widget<TextFormField>(textFields.at(1)).controller?.text,
      'Secret123!',
    );
  });

  testWidgets('LoginPage navigates to password recovery', (
    WidgetTester tester,
  ) async {
    await pumpLoginPage(
      tester,
      routes: <String, WidgetBuilder>{
        AppRoutePaths.passwordRecovery: (_) =>
            const Scaffold(body: Center(child: Text('Password recovery route'))),
      },
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Forgot password?'));
    await tester.pumpAndSettle();

    expect(find.text('Password recovery route'), findsOneWidget);
  });

  testWidgets('LoginPage navigates to sign up', (WidgetTester tester) async {
    await pumpLoginPage(
      tester,
      routes: <String, WidgetBuilder>{
        AppRoutePaths.signUp: (_) =>
            const Scaffold(body: Center(child: Text('Sign up route'))),
      },
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.widgetWithText(TextButton, 'Create account'));
    await tester.tap(find.widgetWithText(TextButton, 'Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Sign up route'), findsOneWidget);
  });
}

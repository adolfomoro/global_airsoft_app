import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_airsoft_app/src/app/routing/app_route_paths.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/pages/sign_up_page.dart';

void main() {
  Future<void> pumpSignUpPage(
    WidgetTester tester, {
    Widget? home,
    GlobalKey<NavigatorState>? navigatorKey,
    Map<String, WidgetBuilder> routes = const <String, WidgetBuilder>{},
  }) {
    return tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          navigatorKey: navigatorKey,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          routes: routes,
          home: home ?? const SignUpPage(),
        ),
      ),
    );
  }

  testWidgets('SignUpPage renders key presentation fields', (
    WidgetTester tester,
  ) async {
    await pumpSignUpPage(tester);
    await tester.pumpAndSettle();

    expect(find.byType(SignUpPage), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('Create your account'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(5));
    expect(
      find.widgetWithText(ElevatedButton, 'Create account'),
      findsOneWidget,
    );
  });

  testWidgets('SignUpPage shows password mismatch feedback', (
    WidgetTester tester,
  ) async {
    await pumpSignUpPage(tester);
    await tester.pumpAndSettle();

    final passwordFields = find.byType(TextFormField);

    await tester.enterText(passwordFields.at(3), 'Abcdef1!');
    await tester.enterText(passwordFields.at(4), 'Mismatch1!');
    await tester.pump();

    expect(find.text('Passwords do not match.'), findsOneWidget);
  });

  testWidgets('SignUpPage shows password requirements while editing password', (
    WidgetTester tester,
  ) async {
    await pumpSignUpPage(tester);
    await tester.pumpAndSettle();

    final passwordField = find.byType(TextFormField).at(3);
    await tester.tap(passwordField);
    await tester.enterText(passwordField, 'abc');
    await tester.pump();

    expect(find.text('Your password must contain:'), findsOneWidget);
  });

  testWidgets('SignUpPage moves focus from username to email on next action', (
    WidgetTester tester,
  ) async {
    await pumpSignUpPage(tester);
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    final usernameField = fields.at(1);
    final emailField = fields.at(2);

    await tester.tap(usernameField);
    await tester.pump();

    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();

    final emailEditableText = tester.widget<EditableText>(
      find.descendant(of: emailField, matching: find.byType(EditableText)),
    );

    expect(emailEditableText.focusNode.hasFocus, isTrue);
  });

  testWidgets('SignUpPage sign in action pops back to previous route', (
    WidgetTester tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();

    await pumpSignUpPage(
      tester,
      navigatorKey: navigatorKey,
      home: const Scaffold(body: Center(child: Text('Login route'))),
      routes: <String, WidgetBuilder>{
        AppRoutePaths.signUp: (_) => const SignUpPage(),
      },
    );
    await tester.pumpAndSettle();

    unawaited(navigatorKey.currentState!.pushNamed(AppRoutePaths.signUp));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.widgetWithText(TextButton, 'Back to login'),
    );
    await tester.tap(find.widgetWithText(TextButton, 'Back to login'));
    await tester.pumpAndSettle();

    expect(find.text('Login route'), findsOneWidget);
  });
}

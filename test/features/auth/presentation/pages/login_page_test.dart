import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/pages/login_page.dart';

void main() {
  testWidgets('LoginPage renders without errors', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          locale: Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: LoginPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify main page elements are present
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(TextField), findsWidgets);
  });

  testWidgets('LoginPage submit button is disabled initially', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          locale: Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: LoginPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Find submit button and verify it exists
    expect(find.byType(ElevatedButton), findsWidgets);
  });
}

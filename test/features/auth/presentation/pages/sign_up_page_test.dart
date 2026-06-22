import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/pages/sign_up_page.dart';

void main() {
  testWidgets('SignUpPage renders without errors', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          locale: Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: SignUpPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify main page elements are present
    expect(find.byType(SignUpPage), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byType(TextField), findsWidgets);
  });

  testWidgets('SignUpPage submit button exists', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          locale: Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: SignUpPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Find submit button and verify it exists
    expect(find.byType(ElevatedButton), findsWidgets);
  });
}

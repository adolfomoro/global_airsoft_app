import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/pages/password_recovery_page.dart';

void main() {
  Future<void> pumpPasswordRecoveryPage(WidgetTester tester) {
    return tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          locale: Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: PasswordRecoveryPage(),
        ),
      ),
    );
  }

  testWidgets('PasswordRecoveryPage renders key presentation fields', (
    WidgetTester tester,
  ) async {
    await pumpPasswordRecoveryPage(tester);
    await tester.pumpAndSettle();

    expect(find.byType(PasswordRecoveryPage), findsOneWidget);
    expect(find.text('Reset password'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('Send recovery link'), findsOneWidget);
  });

  testWidgets('PasswordRecoveryPage accepts email input', (
    WidgetTester tester,
  ) async {
    await pumpPasswordRecoveryPage(tester);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'player@example.com');
    await tester.pump();

    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller?.text,
      'player@example.com',
    );
  });

  testWidgets('PasswordRecoveryPage keeps submit action visible after typing', (
    WidgetTester tester,
  ) async {
    await pumpPasswordRecoveryPage(tester);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'player@example.com');
    await tester.pump();

    expect(find.widgetWithText(ElevatedButton, 'Send recovery link'), findsOneWidget);
  });
}

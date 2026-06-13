import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/widgets/password_requirements_hint.dart';

Widget _wrapWithMaterialApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('hides the hint when empty and unfocused', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrapWithMaterialApp(
        const PasswordRequirementsHint(currentPassword: '', isFocused: false),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(PasswordRequirementsHint), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsNothing);
    expect(find.text('Your password must contain:'), findsNothing);
  });

  testWidgets('shows fixed password rules in gray when focused and empty', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrapWithMaterialApp(
        const PasswordRequirementsHint(currentPassword: '', isFocused: true),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Your password must contain:'), findsOneWidget);
    expect(find.text('At least 8 characters'), findsOneWidget);
    expect(find.text('One letter and one number'), findsOneWidget);
    expect(find.text('One special character'), findsOneWidget);

    final ThemeData theme = Theme.of(tester.element(find.byType(Scaffold)));
    final Color expectedInactiveColor = theme.colorScheme.onSurfaceVariant;

    final List<Icon> icons = tester
        .widgetList<Icon>(find.byIcon(Icons.check_circle_outline))
        .toList(growable: false);

    expect(icons, hasLength(3));
    for (final Icon icon in icons) {
      expect(icon.color, expectedInactiveColor);
    }
  });

  testWidgets('shows fixed password rules when unfocused with partial input', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrapWithMaterialApp(
        const PasswordRequirementsHint(
          currentPassword: 'abc',
          isFocused: false,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Your password must contain:'), findsOneWidget);
    expect(find.text('At least 8 characters'), findsOneWidget);
    expect(find.text('One letter and one number'), findsOneWidget);
    expect(find.text('One special character'), findsOneWidget);
  });

  testWidgets('hides the hint when password is valid', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrapWithMaterialApp(
        const PasswordRequirementsHint(
          currentPassword: 'abC123!x',
          isFocused: false,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(PasswordRequirementsHint), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsNothing);
    expect(find.text('Your password must contain:'), findsNothing);
  });
}

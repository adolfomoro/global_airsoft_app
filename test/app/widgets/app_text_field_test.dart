import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_airsoft_app/src/app/widgets/app_text_field.dart';

void main() {
  testWidgets('wraps long error text on multiple lines', (
    WidgetTester tester,
  ) async {
    const String longErrorText =
        'This error is intentionally long so it should wrap instead of showing ellipsis.';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 220,
            child: AppTextField(
              labelText: 'Username',
              errorText: longErrorText,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final Text errorTextWidget = tester.widget<Text>(find.text(longErrorText));
    expect(errorTextWidget.maxLines, 4);
  });
}

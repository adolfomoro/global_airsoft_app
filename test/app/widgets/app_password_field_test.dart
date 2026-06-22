import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_airsoft_app/src/core/widgets/form/app_password_field.dart';

void main() {
  testWidgets('toggles password visibility from the suffix action', (
    WidgetTester tester,
  ) async {
    final controller = TextEditingController(text: 'Secret123!');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppPasswordField(
            labelText: 'Password',
            controller: controller,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
  });
}
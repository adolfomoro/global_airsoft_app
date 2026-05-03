import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/core/widgets/app_leave_confirmation_guard.dart';

void main() {
  testWidgets('prompts before leaving when there are unsaved changes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const _GuardTestApp());
    await tester.tap(find.byKey(const Key('open-guard-page')));
    await tester.pumpAndSettle();

    expect(find.text('guard-page'), findsOneWidget);

    await tester.tap(find.byKey(const Key('request-back')));
    await tester.pumpAndSettle();

    expect(find.text('Discard your changes?'), findsOneWidget);

    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();

    expect(find.text('guard-page'), findsOneWidget);

    await tester.tap(find.byKey(const Key('request-back')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard changes'));
    await tester.pumpAndSettle();

    expect(find.text('root-page'), findsOneWidget);
    expect(find.text('guard-page'), findsNothing);
  });

  testWidgets('allows cancel action to leave without showing the dialog', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const _GuardTestApp());
    await tester.tap(find.byKey(const Key('open-guard-page')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('cancel-without-dialog')));
    await tester.pumpAndSettle();

    expect(find.text('Discard your changes?'), findsNothing);
    expect(find.text('root-page'), findsOneWidget);
  });
}

class _GuardTestApp extends StatelessWidget {
  const _GuardTestApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Builder(
        builder: (BuildContext context) {
          return Scaffold(
            body: Column(
              children: <Widget>[
                const Text('root-page'),
                ElevatedButton(
                  key: const Key('open-guard-page'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) {
                          return const _GuardPage();
                        },
                      ),
                    );
                  },
                  child: const Text('open'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GuardPage extends StatefulWidget {
  const _GuardPage();

  @override
  State<_GuardPage> createState() => _GuardPageState();
}

class _GuardPageState extends State<_GuardPage> {
  final AppLeaveConfirmationController _controller =
      AppLeaveConfirmationController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppLeaveConfirmationGuard(
        controller: _controller,
        hasUnsavedChanges: true,
        child: Column(
          children: <Widget>[
            const Text('guard-page'),
            ElevatedButton(
              key: const Key('request-back'),
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('back'),
            ),
            ElevatedButton(
              key: const Key('cancel-without-dialog'),
              onPressed: () {
                _controller.dismiss(context);
              },
              child: const Text('cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

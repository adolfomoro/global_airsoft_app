import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_airsoft_app/src/core/network/api_exception.dart';
import 'package:global_airsoft_app/src/core/network/auth_security_handled_exception.dart';
import 'package:global_airsoft_app/src/core/network/message_resolution_policy.dart';
import 'package:global_airsoft_app/src/core/widgets/app_snack_bar_presenter.dart';
import 'package:global_airsoft_app/src/features/auth/data/exceptions/authentication_exception.dart';

void main() {
  testWidgets(
    'does not show duplicate snackbar for wrapped security interceptor errors',
    (WidgetTester tester) async {
      late BuildContext capturedContext;
      final AuthenticationException source =
          AuthenticationException.fromApiException(
            const AuthSecurityHandledException(
              message: 'Backend security change message.',
              statusCode: 401,
              code: 'GlobalAirsoft:Auth:AccessTokenInvalid',
            ),
            messageOverride: 'Localized login failed message.',
          );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                capturedContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      final bool shown = AppSnackBarPresenter.showError(
        capturedContext,
        source.message!,
        source: source,
      );

      await tester.pump();

      expect(shown, isFalse);
      expect(find.text('Backend security change message.'), findsNothing);
    },
  );

  testWidgets('shows snackbar for wrapped feature-managed failures', (
    WidgetTester tester,
  ) async {
    late BuildContext capturedContext;
    final AuthenticationException source =
        AuthenticationException.fromApiException(
          const UnknownApiException(
            message: 'Connection error while calling API.',
            isFallbackMessage: true,
          ),
          messageOverride: 'Localized login failed message.',
          messageOverrideBehavior: MessageOverrideBehavior.useAsFallback,
        );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              capturedContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    final bool shown = AppSnackBarPresenter.showError(
      capturedContext,
      source.message!,
      source: source,
    );

    await tester.pump();

    expect(shown, isTrue);
    expect(find.text('Localized login failed message.'), findsOneWidget);
  });
}

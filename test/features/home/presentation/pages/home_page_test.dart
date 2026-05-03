import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/features/home/presentation/pages/home_page.dart';
import 'package:global_airsoft_app/src/features/users/application/providers/users_providers.dart';
import 'package:global_airsoft_app/src/features/users/domain/models/user_profile.dart';

void main() {
  testWidgets('switches tabs and renders current user profile content', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProfileProvider.overrideWith((Ref ref) async {
            return const UserProfile(
              id: 'user-1',
              username: 'marcus.kane',
              fullName: 'Marcus Kane',
              bio:
                  'CQB-focused player who also enjoys long-form weekend milsim events.',
              mediumProfilePictureUrl: '',
              largeProfilePictureUrl: '',
            );
          }),
        ],
        child: MaterialApp(
          locale: Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: HomePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Game discovery will be connected here next.'),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.person_outline_rounded));
    await tester.pumpAndSettle();

    expect(find.text('@marcus.kane'), findsOneWidget);
    expect(find.text('Marcus Kane'), findsOneWidget);
    expect(
      find.text(
        'CQB-focused player who also enjoys long-form weekend milsim events.',
      ),
      findsOneWidget,
    );
    expect(find.text('Bio'), findsOneWidget);
    expect(find.text('Logout'), findsNothing);
  });
}

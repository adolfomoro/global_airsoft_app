import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_defaults.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_service.dart';
import 'package:global_airsoft_app/src/core/localization/app_localizations.dart';
import 'package:global_airsoft_app/src/core/storage/key_value_store.dart';
import 'package:global_airsoft_app/src/core/validation/validation_mapping_result.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/support/auth_presentation_extensions.dart';
import 'package:global_airsoft_app/src/features/users/application/providers/current_user_profile_providers.dart';
import 'package:global_airsoft_app/src/features/users/domain/models/user_profile.dart';

final class _InMemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> data = <String, String>{};

  @override
  String? getString(String key) {
    return data[key];
  }

  @override
  Future<void> remove(String key) async {
    data.remove(key);
  }

  @override
  Future<void> setString(String key, String value) async {
    data[key] = value;
  }
}

final class _TestCurrentUserProfileController
    extends CurrentUserProfileController {
  static int buildCount = 0;

  static void reset() {
    buildCount = 0;
  }

  @override
  Future<UserProfile> build() async {
    buildCount += 1;

    return const UserProfile(
      id: 'user-1',
      username: 'player.one',
      fullName: 'Player One',
      bio: '',
      mediumProfilePictureUrl: '',
      largeProfilePictureUrl: '',
    );
  }
}

void main() {
  test('returns the first non-empty global error', () {
    const ValidationMappingResult result = ValidationMappingResult(
      fieldErrors: <String, String>{},
      globalErrors: <String>['  ', '', 'Primary error', 'Secondary error'],
    );

    expect(result.firstMeaningfulGlobalError, 'Primary error');
  });

  test('returns null when all global errors are empty', () {
    const ValidationMappingResult result = ValidationMappingResult(
      fieldErrors: <String, String>{},
      globalErrors: <String>['', '   '],
    );

    expect(result.firstMeaningfulGlobalError, isNull);
  });

  testWidgets(
    'completeAuthenticatedSession invalidates profile state and clears refresh request',
    (WidgetTester tester) async {
      _TestCurrentUserProfileController.reset();

      late WidgetRef capturedRef;
      final AppLocaleService localeService = AppLocaleService(
        store: _InMemoryKeyValueStore(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appLocaleServiceProvider.overrideWithValue(localeService),
            initialAppLocaleProvider.overrideWithValue(
              AppLocalizations.fallbackLocale,
            ),
            initialIsAuthenticatedProvider.overrideWithValue(false),
            currentUserProfileProvider.overrideWith(
              _TestCurrentUserProfileController.new,
            ),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (BuildContext context, WidgetRef ref, _) {
                capturedRef = ref;
                ref.watch(currentUserProfileProvider);

                return TextButton(
                  onPressed: () async {
                    await ref.completeAuthenticatedSession();
                  },
                  child: const Text('Complete session'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      capturedRef
          .read(currentUserProfileRefreshRequestProvider.notifier)
          .requestRefresh();
      expect(
        capturedRef.read(currentUserProfileRefreshRequestProvider),
        isTrue,
      );
      expect(_TestCurrentUserProfileController.buildCount, 1);

      await tester.tap(find.text('Complete session'));
      await tester.pumpAndSettle();

      expect(capturedRef.read(isAuthenticatedProvider), isTrue);
      expect(
        capturedRef.read(currentUserProfileRefreshRequestProvider),
        isFalse,
      );
      expect(_TestCurrentUserProfileController.buildCount, 2);
    },
  );
}

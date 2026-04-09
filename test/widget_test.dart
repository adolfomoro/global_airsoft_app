import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:global_airsoft_app/src/app/app.dart';
import 'package:global_airsoft_app/src/app/theme/theme_preference.dart';
import 'package:global_airsoft_app/src/app/theme/theme_preference_service.dart';
import 'package:global_airsoft_app/src/app/theme/theme_providers.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_providers.dart';
import 'package:global_airsoft_app/src/core/localization/app_locale_service.dart';
import 'package:global_airsoft_app/src/core/storage/key_value_store.dart';

final class _InMemoryStore implements KeyValueStore {
  final Map<String, String> _data = <String, String>{};

  @override
  String? getString(String key) {
    return _data[key];
  }

  @override
  Future<void> setString(String key, String value) async {
    _data[key] = value;
  }
}

void main() {
  testWidgets('renders startup shell', (WidgetTester tester) async {
    final _InMemoryStore store = _InMemoryStore();
    final ThemePreferenceService service = ThemePreferenceService(store: store);
    final AppLocaleService localeService = AppLocaleService(store: store);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          themePreferenceServiceProvider.overrideWithValue(service),
          initialThemePreferenceProvider.overrideWithValue(
            AppThemePreference.dark,
          ),
          appLocaleServiceProvider.overrideWithValue(localeService),
        ],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Global Airsoft App'), findsOneWidget);
  });
}

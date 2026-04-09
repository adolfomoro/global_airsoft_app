import 'package:global_airsoft_app/src/app/theme/theme_preference.dart';
import 'package:global_airsoft_app/src/core/storage/key_value_store.dart';

final class ThemePreferenceService {
  ThemePreferenceService({required KeyValueStore store}) : _store = store;

  static const String _themePreferenceKey = 'ui_theme_preference';

  final KeyValueStore _store;

  AppThemePreference readPreference() {
    final String? rawValue = _store.getString(_themePreferenceKey);
    return AppThemePreferenceX.fromStorageValue(rawValue);
  }

  Future<void> savePreference(AppThemePreference preference) async {
    await _store.setString(_themePreferenceKey, preference.storageValue);
  }
}

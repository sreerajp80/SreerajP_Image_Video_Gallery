import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Where the in-app language choice is kept (engineering standard §8.4).
///
/// The standard names the place exactly: `SharedPreferences` key
/// `app_language`, value `system` or a declared language code. The language
/// is not a secret, so plain preferences are right for it; the app's other
/// preferences stay in their JSON file (`AppSettingsService`).
abstract class LanguagePreferenceStore {
  /// The stored value, or null when the user never chose.
  Future<String?> read();

  /// Stores [value]: `system` or a language code.
  Future<void> write(String value);
}

/// The real store, over `SharedPreferences`.
class SharedPreferencesLanguageStore implements LanguagePreferenceStore {
  final SharedPreferencesAsync _prefs;

  SharedPreferencesLanguageStore({SharedPreferencesAsync? prefs})
    : _prefs = prefs ?? SharedPreferencesAsync();

  @override
  Future<String?> read() =>
      _prefs.getString(AppConstants.languagePreferenceKey);

  @override
  Future<void> write(String value) =>
      _prefs.setString(AppConstants.languagePreferenceKey, value);
}

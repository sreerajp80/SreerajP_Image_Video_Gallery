import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/core/storage/atomic_saver.dart';
import 'package:in_sreerajp_imgvidgal/models/settings/app_settings.dart';
import 'package:in_sreerajp_imgvidgal/services/settings/language_preference_store.dart';
import 'package:path/path.dart' as p;
import 'package:in_sreerajp_imgvidgal/core/logging/app_logger.dart';

/// Keeps the user's preferences in one small JSON file.
///
/// The same shape as the recent-searches store: one file, written through
/// [AtomicSaver] so a crash mid-write cannot leave half a file behind, and
/// nothing here ever throws at the caller. A missing, unreadable, or corrupt
/// file simply means "defaults", and a failed write is dropped.
///
/// That is deliberate. Preferences are a convenience. Failing a launch, or
/// throwing a dialog at somebody, because a settings file went bad would be a
/// worse outcome than quietly starting from the defaults.
///
/// This is not secure storage on purpose. Theme, language, grid density and
/// two switches are not secrets. The vault keeps its own settings in
/// `flutter_secure_storage`, and that stays where it is.
///
/// The one exception is the language. Engineering standard §8.4 names its
/// place exactly (`SharedPreferences`, key `app_language`), so when a
/// [languageStore] is given the language is read from and written to it, and
/// not to the JSON file. Older files still hold a `localeCode`; the first
/// load moves it across once (G10).
class AppSettingsService {
  /// Folder the settings file is kept in.
  final Directory directory;

  /// Where the language choice is kept, or null to keep it in the JSON file.
  final LanguagePreferenceStore? languageStore;

  const AppSettingsService({required this.directory, this.languageStore});

  /// Value stored under [AppConstants.languagePreferenceKey] when the app
  /// follows the phone's language.
  static const String systemLanguageValue = 'system';

  /// Full path of the settings file.
  String get filePath =>
      p.join(directory.path, AppConstants.appSettingsFileName);

  /// Reads the stored preferences, or the defaults if there are none.
  Future<AppSettings> load() async {
    return _withStoredLanguage(await _loadFile());
  }

  Future<AppSettings> _loadFile() async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return AppSettings.defaults;

      return AppSettings.fromJson(jsonDecode(await file.readAsString()));
    } catch (error) {
      AppLogger.warning(
        'Settings were unreadable; defaults used',
        error: error,
      );
      // Missing, truncated, or hand-edited into nonsense. Start clean.
      return AppSettings.defaults;
    }
  }

  /// Puts the language from [languageStore] into [fromFile].
  ///
  /// When the store has no value yet, the file's old `localeCode` (if any) is
  /// written to the store, so nobody loses the language they picked before
  /// the key moved.
  Future<AppSettings> _withStoredLanguage(AppSettings fromFile) async {
    final store = languageStore;
    if (store == null) return fromFile;
    try {
      final stored = await store.read();
      if (stored == null) {
        await store.write(fromFile.localeCode ?? systemLanguageValue);
        return fromFile;
      }
      if (AppConstants.supportedLocaleCodes.contains(stored)) {
        return fromFile.copyWith(localeCode: stored);
      }
      // `system`, or a value the app does not ship: follow the phone.
      return fromFile.copyWith(clearLocaleCode: true);
    } catch (error) {
      AppLogger.warning('Language preference was unreadable', error: error);
      return fromFile;
    }
  }

  /// Writes [settings] to disk.
  ///
  /// Returns whether the write landed. Callers may ignore it: the in-memory
  /// state is already correct either way, and only the next launch would
  /// notice that a save was lost.
  Future<bool> save(AppSettings settings) async {
    try {
      final map = settings.toJson();
      final store = languageStore;
      if (store != null) {
        await store.write(settings.localeCode ?? systemLanguageValue);
        // The language has its own home now; keep one source of truth.
        map.remove('localeCode');
      }
      final json = jsonEncode(map);
      await AtomicSaver.writeBytes(
        filePath,
        Uint8List.fromList(utf8.encode(json)),
      );
      return true;
    } catch (error) {
      AppLogger.warning('Saving settings failed', error: error);
      // A full disk must not stop somebody changing their theme.
      return false;
    }
  }
}

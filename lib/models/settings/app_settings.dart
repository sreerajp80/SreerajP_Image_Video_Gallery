import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/theme/app_theme.dart';

/// The preferences the user can change on the Settings screen.
///
/// Deliberately small, and deliberately not secret. None of these values
/// is worth protecting, so they live in a plain JSON file rather than secure
/// storage. The vault keeps its own settings, in its own encrypted store.
///
/// Immutable, like every other model in the app: change one with [copyWith].
class AppSettings {
  /// Which theme the app paints in.
  final ThemePreference theme;

  /// Language code, or `null` to follow the phone's own language.
  ///
  /// Only `'en'`, `'ml'` and `'sa'` are accepted; anything else is dropped on
  /// read.
  final String? localeCode;

  /// How many columns the timeline grid starts at, always 1 to 5.
  final int gridColumns;

  /// Whether the timeline shows the flashback memories row.
  final bool showFlashbacks;

  /// Whether an extra confirmation is asked before anything destructive.
  ///
  /// On by default. Turning it off never removes a confirmation that guards
  /// a file the app cannot bring back.
  final bool confirmDestructive;

  /// Whether every screen is protected from screenshots, screen recording
  /// and the recent-apps preview (`FLAG_SECURE`), not only the vault.
  ///
  /// Off by default: blocking a screenshot of an ordinary photo is not what
  /// most people want. The vault is always protected, whatever this says
  /// (G28, `docs/security.md` §10).
  final bool protectAllScreens;

  /// Whether a permanent delete writes over each file before removing it,
  /// so undelete tools cannot get it back.
  ///
  /// Covers "Delete permanently" from the gallery and every delete from the
  /// trash. Off by default: it is slower and Android asks for permission to
  /// modify the files first. Vault deletes ignore this and always shred.
  final bool secureDelete;

  const AppSettings({
    this.theme = ThemePreference.system,
    this.localeCode,
    this.gridColumns = AppConstants.defaultGridColumns,
    this.showFlashbacks = true,
    this.confirmDestructive = true,
    this.protectAllScreens = false,
    this.secureDelete = false,
  });

  /// What a phone that has never opened the Settings screen uses.
  static const AppSettings defaults = AppSettings();

  AppSettings copyWith({
    ThemePreference? theme,
    String? localeCode,
    bool clearLocaleCode = false,
    int? gridColumns,
    bool? showFlashbacks,
    bool? confirmDestructive,
    bool? protectAllScreens,
    bool? secureDelete,
  }) {
    return AppSettings(
      theme: theme ?? this.theme,
      // A null localeCode means "unchanged", so following the phone again
      // needs its own flag rather than a null nobody can tell apart.
      localeCode: clearLocaleCode ? null : (localeCode ?? this.localeCode),
      gridColumns: _clampColumns(gridColumns ?? this.gridColumns),
      showFlashbacks: showFlashbacks ?? this.showFlashbacks,
      confirmDestructive: confirmDestructive ?? this.confirmDestructive,
      protectAllScreens: protectAllScreens ?? this.protectAllScreens,
      secureDelete: secureDelete ?? this.secureDelete,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'theme': theme.name,
      'localeCode': localeCode,
      'gridColumns': gridColumns,
      'showFlashbacks': showFlashbacks,
      'confirmDestructive': confirmDestructive,
      'protectAllScreens': protectAllScreens,
      'secureDelete': secureDelete,
    };
  }

  /// Reads settings out of decoded JSON, field by field.
  ///
  /// Never throws and never returns null. A missing field, a wrong type, a
  /// column count outside 1 to 5, or a language the app does not ship all
  /// fall back to the default for that one field, leaving the rest intact.
  /// A hand-edited file must not cost somebody every other preference.
  static AppSettings fromJson(Object? raw) {
    if (raw is! Map) return defaults;

    return AppSettings(
      theme: _parseTheme(raw['theme']),
      localeCode: _parseLocaleCode(raw['localeCode']),
      gridColumns: _parseColumns(raw['gridColumns']),
      showFlashbacks: _parseBool(
        raw['showFlashbacks'],
        defaults.showFlashbacks,
      ),
      confirmDestructive: _parseBool(
        raw['confirmDestructive'],
        defaults.confirmDestructive,
      ),
      protectAllScreens: _parseBool(
        raw['protectAllScreens'],
        defaults.protectAllScreens,
      ),
      secureDelete: _parseBool(raw['secureDelete'], defaults.secureDelete),
    );
  }

  static ThemePreference _parseTheme(Object? value) {
    if (value is! String) return defaults.theme;
    for (final preference in ThemePreference.values) {
      if (preference.name == value) return preference;
    }
    return defaults.theme;
  }

  static String? _parseLocaleCode(Object? value) {
    if (value is! String) return null;
    return AppConstants.supportedLocaleCodes.contains(value) ? value : null;
  }

  static int _parseColumns(Object? value) {
    if (value is int) return _clampColumns(value);
    return defaults.gridColumns;
  }

  static bool _parseBool(Object? value, bool fallback) {
    return value is bool ? value : fallback;
  }

  static int _clampColumns(int value) {
    if (value < AppConstants.minGridColumns) return AppConstants.minGridColumns;
    if (value > AppConstants.maxGridColumns) return AppConstants.maxGridColumns;
    return value;
  }

  @override
  bool operator ==(Object other) {
    return other is AppSettings &&
        other.theme == theme &&
        other.localeCode == localeCode &&
        other.gridColumns == gridColumns &&
        other.showFlashbacks == showFlashbacks &&
        other.confirmDestructive == confirmDestructive &&
        other.protectAllScreens == protectAllScreens &&
        other.secureDelete == secureDelete;
  }

  @override
  int get hashCode => Object.hash(
    theme,
    localeCode,
    gridColumns,
    showFlashbacks,
    confirmDestructive,
    protectAllScreens,
    secureDelete,
  );
}

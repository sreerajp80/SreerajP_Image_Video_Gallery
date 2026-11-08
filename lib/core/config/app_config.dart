/// A config text that is either one string for every language or one string
/// per locale code (`en`, `ml`, `sa`).
///
/// Resolution order: the exact language, then English, then any value.
class LocalizedText {
  final Map<String, String> _byLocale;
  final String _plain;

  const LocalizedText.plain(String value)
    : _plain = value,
      _byLocale = const {};

  const LocalizedText.byLocale(Map<String, String> byLocale)
    : _plain = '',
      _byLocale = byLocale;

  bool get isEmpty =>
      _plain.trim().isEmpty && _byLocale.values.every((v) => v.trim().isEmpty);

  /// [languageCode] is the active app language: `en`, `ml` or `sa`.
  String resolve(String languageCode) {
    if (_byLocale.isEmpty) return _plain;
    return _byLocale[languageCode] ?? _byLocale['en'] ?? _byLocale.values.first;
  }

  /// Accepts a JSON string or a `{"en": ..., "ml": ..., "sa": ...}` map.
  /// Anything else becomes [fallback]; this never throws.
  factory LocalizedText.fromJson(Object? raw, {String fallback = ''}) {
    if (raw is String) return LocalizedText.plain(raw);
    if (raw is Map) {
      final out = <String, String>{};
      raw.forEach((k, v) {
        if (k is String && v is String) out[k] = v;
      });
      if (out.isNotEmpty) return LocalizedText.byLocale(out);
    }
    return LocalizedText.plain(fallback);
  }
}

/// Typed values for the About screen, loaded from `assets/config/app_config.json`.
/// Changing About content is a config edit, not a code change.
class AppConfig {
  final LocalizedText appName;
  final LocalizedText description;
  final String version;
  final String build;

  /// Detail rows, in file order. Keys are `lowerCamelCase` identifiers; the
  /// visible label comes from the ARB key `aboutDetail<Key>`.
  final Map<String, LocalizedText> details;

  const AppConfig({
    required this.appName,
    required this.description,
    required this.version,
    required this.build,
    this.details = const {},
  });

  /// Safe built-in value used when the config file is missing or malformed,
  /// so the app never crashes on a bad config.
  static const AppConfig fallback = AppConfig(
    appName: LocalizedText.byLocale({
      'en': 'Drishya Gallery',
      'ml': 'ദൃശ്യ',
      'sa': 'दृश्य',
    }),
    description: LocalizedText.plain(
      'Offline-first image and video gallery application.',
    ),
    version: '1.0.0',
    build: '1',
    details: {
      'license': LocalizedText.plain('All libraries used are open source.'),
    },
  );

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    String str(String key, String fallbackValue) {
      final value = json[key];
      return value is String ? value : fallbackValue;
    }

    Map<String, LocalizedText> parseDetails(String key) {
      final raw = json[key];
      if (raw is! Map) return const {};
      final out = <String, LocalizedText>{};
      raw.forEach((k, v) {
        if (k is String) {
          final text = LocalizedText.fromJson(v);
          if (!text.isEmpty) out[k] = text;
        }
      });
      return out;
    }

    return AppConfig(
      appName: LocalizedText.fromJson(
        json['appName'],
        fallback: fallback.appName.resolve('en'),
      ),
      description: LocalizedText.fromJson(
        json['description'],
        fallback: fallback.description.resolve('en'),
      ),
      version: str('version', fallback.version),
      build: str('build', fallback.build),
      details: parseDetails('details'),
    );
  }
}

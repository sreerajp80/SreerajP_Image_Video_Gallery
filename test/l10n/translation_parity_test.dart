import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart' show StringCharacters;
import 'package:flutter_test/flutter_test.dart';

/// Every language ships every string (engineering standard §8.2, §8.7).
///
/// This is the gate that stops a key from being added to `app_en.arb` alone.
void main() {
  const locales = <String>['ml', 'sa'];

  /// Keys that may equal English: technical names, format-only strings, and
  /// the English endonym on the language picker. Keep this list short.
  const sameAsEnglishAllowed = <String>{
    // File formats and camera terms.
    'labelBadgeGif',
    'labelBadgeHd',
    'labelBadgeRaw',
    'labelCompareIso',
    'labelDetailsIso',
    'labelFilterTypeRaw',
    'labelFilterTypeSvg',
    'tabVideoTabGif',
    // Aspect ratios and paper size.
    'labelCropAspect16x9',
    'labelCropAspect2x3',
    'labelCropAspect3x2',
    'labelCropAspect3x4',
    'labelCropAspect4x3',
    'labelCropAspect9x16',
    'labelPdfPageA4',
    // Unit symbols and standard names around a number (§8.2). Malayalam and
    // Sanskrit apps write these symbols as they are.
    'bodyUnitBytes',
    'bodyUnitKilobytes',
    'bodyUnitMegabytes',
    'bodyUnitGigabytes',
    'bodyUnitTerabytes',
    'bodyUnitMillimetres',
    'bodyUnitMetres',
    'bodyUnitIsoValue',
    'bodyUnitCropFactor',
    'bodyPdfImageFormatAndSize',
    'bodyA11yPercentValue',
    // Placeholders only.
    'labelCompareBadge',
    // Language picker endonyms (§8.4).
    'titleLanguageEnglish',
    'titleLanguageMalayalam',
    'titleLanguageSanskrit',
  };

  Map<String, dynamic> readArb(String locale) =>
      jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
          as Map<String, dynamic>;

  Map<String, String> strings(Map<String, dynamic> arb) => <String, String>{
    for (final e in arb.entries)
      if (!e.key.startsWith('@')) e.key: e.value as String,
  };

  final en = readArb('en');
  final enStrings = strings(en);

  group('ARB parity', () {
    test('the template gives every key a description', () {
      final missing = <String>[
        for (final key in enStrings.keys)
          if ((en['@$key'] as Map?)?['description'] == null) key,
      ];
      expect(missing, isEmpty, reason: missing.join('\n'));
    });

    for (final locale in locales) {
      group(locale, () {
        final arb = readArb(locale);
        final other = strings(arb);

        test('declares its locale', () {
          expect(arb['@@locale'], locale);
        });

        test('has exactly the template keys', () {
          final missing = enStrings.keys.toSet().difference(other.keys.toSet());
          final extra = other.keys.toSet().difference(enStrings.keys.toSet());
          expect(missing, isEmpty, reason: 'missing in $locale: $missing');
          expect(extra, isEmpty, reason: 'extra in $locale: $extra');
        });

        test('keeps every placeholder', () {
          final problems = <String>[];
          for (final key in enStrings.keys) {
            final meta = en['@$key'] as Map<String, dynamic>?;
            final placeholders =
                (meta?['placeholders'] as Map<String, dynamic>?)?.keys ??
                const <String>[];
            final value = other[key];
            if (value == null) continue;
            for (final name in placeholders) {
              if (!value.contains('{$name}') && !value.contains('{$name,')) {
                problems.add('$key lost {$name}');
              }
            }
          }
          expect(problems, isEmpty, reason: problems.join('\n'));
        });

        test('no value is a copy of the English one', () {
          final problems = <String>[
            for (final e in other.entries)
              if (!sameAsEnglishAllowed.contains(e.key) &&
                  e.value.trim().isNotEmpty &&
                  e.value == enStrings[e.key])
                e.key,
          ];
          expect(problems, isEmpty, reason: problems.join('\n'));
        });
      });
    }

    test('madeWithLove keeps the {heart} marker in all three languages', () {
      for (final locale in <String>['en', ...locales]) {
        final text = strings(readArb(locale))['madeWithLove'];
        expect(text, contains('{heart}'), reason: 'app_$locale.arb');
      }
    });
  });

  group('Label length (§8.6)', () {
    const shortPrefix = r'^(action|label|title|tab|nav|tooltip)[A-Z]';
    const anyPrefix =
        r'^(action|label|title|tab|nav|tooltip|desc|help|empty|error|body|'
        r'aboutDetail)[A-Z0-9]';
    const limits = <String, int>{'en': 20, 'ml': 22, 'sa': 22};

    /// The fixed keys `guideline.md` names, which keep their own names.
    const fixedKeys = <String>{'madeWithLove', 'madeWithLoveA11y'};

    test('every key carries a category prefix', () {
      final missing = strings(readArb('en')).keys
          .where((key) => !fixedKeys.contains(key))
          .where((key) => !RegExp(anyPrefix).hasMatch(key))
          .toList();
      expect(missing, isEmpty, reason: missing.join('\n'));
    });

    for (final locale in limits.keys) {
      test('$locale short labels fit the budget', () {
        // No exceptions: every short label in every language fits (G50 fixed
        // 2026-11-05). A label that does not fit gets shorter words.
        final problems = <String>[];
        strings(readArb(locale)).forEach((key, value) {
          if (!RegExp(shortPrefix).hasMatch(key)) return;
          // Placeholders are filled at run time, so only fixed text counts.
          if (value.contains('{')) return;
          if (value.characters.length > limits[locale]!) {
            problems.add('$key (${value.characters.length}): $value');
          }
        });
        expect(problems, isEmpty, reason: problems.join('\n'));
      });
    }
  });

  group('About config parity', () {
    test('app_config.json has all three languages and ARB labels', () {
      final json =
          jsonDecode(File('assets/config/app_config.json').readAsStringSync())
              as Map<String, dynamic>;
      final problems = <String>[];

      void checkLanguages(String path, Object? value) {
        if (value is! Map) {
          problems.add('$path must be an {"en","ml","sa"} map');
          return;
        }
        for (final lang in <String>['en', ...locales]) {
          if ((value[lang]?.toString().trim() ?? '').isEmpty) {
            problems.add('$path.$lang is missing or empty');
          }
        }
      }

      checkLanguages('appName', json['appName']);
      checkLanguages('description', json['description']);

      final details = json['details'] as Map<String, dynamic>;
      for (final entry in details.entries) {
        final id = entry.key;
        // Technical values (an email address) may stay plain strings.
        if (entry.value is Map) checkLanguages('details.$id', entry.value);

        final labelKey = 'aboutDetail${id[0].toUpperCase()}${id.substring(1)}';
        if (!enStrings.containsKey(labelKey)) {
          problems.add('details.$id has no ARB label "$labelKey"');
        }
      }

      expect(problems, isEmpty, reason: problems.join('\n'));
    });
  });
}

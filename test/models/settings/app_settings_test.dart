import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/settings/app_settings.dart';
import 'package:in_sreerajp_imgvidgal/theme/app_theme.dart';

void main() {
  group('AppSettings defaults', () {
    test('a fresh install follows the phone and keeps the guards on', () {
      const settings = AppSettings.defaults;

      expect(settings.theme, ThemePreference.system);
      expect(settings.localeCode, isNull);
      expect(settings.gridColumns, AppConstants.defaultGridColumns);
      expect(settings.showFlashbacks, isTrue);
      // The confirmation before a delete is on unless someone turns it off.
      expect(settings.confirmDestructive, isTrue);
    });
  });

  group('AppSettings copyWith', () {
    test('changes one field and leaves the rest alone', () {
      const original = AppSettings(
        theme: ThemePreference.dark,
        localeCode: 'ml',
        gridColumns: 4,
        showFlashbacks: false,
        confirmDestructive: false,
      );

      final updated = original.copyWith(theme: ThemePreference.amoled);

      expect(updated.theme, ThemePreference.amoled);
      expect(updated.localeCode, 'ml');
      expect(updated.gridColumns, 4);
      expect(updated.showFlashbacks, isFalse);
      expect(updated.confirmDestructive, isFalse);
    });

    test('clamps a column count outside the supported range', () {
      const original = AppSettings();

      expect(
        original.copyWith(gridColumns: 0).gridColumns,
        AppConstants.minGridColumns,
      );
      expect(
        original.copyWith(gridColumns: 99).gridColumns,
        AppConstants.maxGridColumns,
      );
    });

    test('needs the clear flag to go back to following the phone', () {
      const original = AppSettings(localeCode: 'ml');

      // A bare null means "unchanged", so it must not drop the language.
      expect(original.copyWith(localeCode: null).localeCode, 'ml');
      expect(original.copyWith(clearLocaleCode: true).localeCode, isNull);
    });
  });

  group('AppSettings JSON', () {
    test('round-trips through encode and decode', () {
      const original = AppSettings(
        theme: ThemePreference.amoled,
        localeCode: 'ml',
        gridColumns: 5,
        showFlashbacks: false,
        confirmDestructive: false,
      );

      final decoded = AppSettings.fromJson(
        jsonDecode(jsonEncode(original.toJson())),
      );

      expect(decoded, original);
    });

    test('a missing field falls back without losing the others', () {
      final decoded = AppSettings.fromJson(<String, Object?>{
        'theme': 'dark',
        'gridColumns': 2,
      });

      expect(decoded.theme, ThemePreference.dark);
      expect(decoded.gridColumns, 2);
      expect(decoded.localeCode, isNull);
      expect(decoded.showFlashbacks, AppSettings.defaults.showFlashbacks);
    });

    test('a wrong type falls back for that field only', () {
      final decoded = AppSettings.fromJson(<String, Object?>{
        'theme': 42,
        'localeCode': <String>['ml'],
        'gridColumns': 'four',
        'showFlashbacks': 'yes',
        'confirmDestructive': false,
      });

      expect(decoded.theme, AppSettings.defaults.theme);
      expect(decoded.localeCode, isNull);
      expect(decoded.gridColumns, AppSettings.defaults.gridColumns);
      expect(decoded.showFlashbacks, AppSettings.defaults.showFlashbacks);
      // The one field that was valid still comes through.
      expect(decoded.confirmDestructive, isFalse);
    });

    test('an unknown theme name falls back to the default', () {
      final decoded = AppSettings.fromJson(<String, Object?>{'theme': 'sepia'});

      expect(decoded.theme, AppSettings.defaults.theme);
    });

    test('a language the app does not ship is dropped', () {
      // Otherwise the app would try to run in a language with no strings.
      final decoded = AppSettings.fromJson(<String, Object?>{
        'localeCode': 'fr',
      });

      expect(decoded.localeCode, isNull);
    });

    test('both shipped languages are accepted', () {
      expect(
        AppSettings.fromJson(<String, Object?>{'localeCode': 'en'}).localeCode,
        'en',
      );
      expect(
        AppSettings.fromJson(<String, Object?>{'localeCode': 'ml'}).localeCode,
        'ml',
      );
    });

    test('a stored column count outside the range is clamped', () {
      expect(
        AppSettings.fromJson(<String, Object?>{'gridColumns': -3}).gridColumns,
        AppConstants.minGridColumns,
      );
      expect(
        AppSettings.fromJson(<String, Object?>{'gridColumns': 40}).gridColumns,
        AppConstants.maxGridColumns,
      );
    });

    test('anything that is not a map gives the defaults', () {
      expect(AppSettings.fromJson(null), AppSettings.defaults);
      expect(AppSettings.fromJson('not settings'), AppSettings.defaults);
      expect(AppSettings.fromJson(<int>[1, 2, 3]), AppSettings.defaults);
    });
  });

  group('AppSettings equality', () {
    test('two settings with the same values are equal', () {
      const a = AppSettings(theme: ThemePreference.light, localeCode: 'en');
      const b = AppSettings(theme: ThemePreference.light, localeCode: 'en');

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('a single different field breaks equality', () {
      const a = AppSettings(localeCode: 'en');
      const b = AppSettings(localeCode: 'ml');

      expect(a, isNot(b));
    });
  });
}

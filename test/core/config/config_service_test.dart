import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/config/app_config.dart';
import 'package:in_sreerajp_imgvidgal/core/config/config_service.dart';

void main() {
  group('LocalizedText', () {
    test('a plain string is the same in every language', () {
      const text = LocalizedText.plain('Sreeraj P');

      expect(text.resolve('en'), 'Sreeraj P');
      expect(text.resolve('ml'), 'Sreeraj P');
      expect(text.resolve('sa'), 'Sreeraj P');
    });

    test('a locale map picks the language, then English', () {
      final text = LocalizedText.fromJson(<String, dynamic>{
        'en': 'Gallery',
        'ml': 'ഗാലറി',
      });

      expect(text.resolve('ml'), 'ഗാലറി');
      expect(text.resolve('en'), 'Gallery');
      expect(text.resolve('sa'), 'Gallery');
    });

    test('a map with no English still resolves to something', () {
      final text = LocalizedText.fromJson(<String, dynamic>{'ml': 'ഗാലറി'});

      expect(text.resolve('sa'), 'ഗാലറി');
    });

    test('a wrong type becomes the fallback and never throws', () {
      expect(LocalizedText.fromJson(42, fallback: 'x').resolve('en'), 'x');
      expect(LocalizedText.fromJson(null).isEmpty, isTrue);
      expect(
        LocalizedText.fromJson(<String, dynamic>{
          'en': 3,
        }, fallback: 'y').resolve('en'),
        'y',
      );
    });
  });

  group('AppConfig', () {
    test('parses valid json successfully', () {
      final json = <String, dynamic>{
        'appName': <String, dynamic>{'en': 'Test Gallery', 'ml': 'ഗാലറി'},
        'description': 'A test gallery app',
        'version': '1.2.3',
        'build': '42',
        'details': <String, dynamic>{
          'author': <String, dynamic>{'en': 'Test Author', 'ml': 'ലേഖകൻ'},
          'license': 'MIT',
        },
      };

      final config = AppConfig.fromJson(json);

      expect(config.appName.resolve('en'), 'Test Gallery');
      expect(config.appName.resolve('ml'), 'ഗാലറി');
      expect(config.description.resolve('ml'), 'A test gallery app');
      expect(config.version, '1.2.3');
      expect(config.build, '42');
      expect(config.details['author']!.resolve('ml'), 'ലേഖകൻ');
      expect(config.details['license']!.resolve('en'), 'MIT');
      expect(config.details.keys, <String>['author', 'license']);
    });

    test('drops detail rows that are empty or the wrong type', () {
      final config = AppConfig.fromJson(<String, dynamic>{
        'details': <String, dynamic>{'a': '  ', 'b': 7, 'c': 'kept'},
      });

      expect(config.details.keys, <String>['c']);
    });

    test('falls back gracefully on empty or malformed json', () {
      final json = <String, dynamic>{};
      final config = AppConfig.fromJson(json);

      expect(
        config.appName.resolve('en'),
        AppConfig.fallback.appName.resolve('en'),
      );
      expect(
        config.description.resolve('en'),
        AppConfig.fallback.description.resolve('en'),
      );
      expect(config.version, AppConfig.fallback.version);
      expect(config.build, AppConfig.fallback.build);
      expect(config.details, isEmpty);
    });
  });

  group('ConfigService', () {
    test('loads and decodes valid JSON through mock loader', () async {
      final service = ConfigService(
        loadAsset: (_) async => '''
        {
          "appName": {"en": "Mock App", "ml": "മോക്ക്"},
          "description": "Mock Description",
          "version": "2.0.0",
          "build": "10",
          "details": {
            "custom": "Value"
          }
        }
        ''',
      );

      final config = await service.load();

      expect(config.appName.resolve('en'), 'Mock App');
      expect(config.version, '2.0.0');
      expect(config.details['custom']!.resolve('en'), 'Value');
    });

    test('returns fallback on asset loading error', () async {
      final service = ConfigService(
        loadAsset: (_) async => throw Exception('Asset missing'),
      );

      final config = await service.load();

      expect(
        config.appName.resolve('en'),
        AppConfig.fallback.appName.resolve('en'),
      );
      expect(config.version, AppConfig.fallback.version);
    });

    test('the shipped config parses and has every display value', () {
      final raw = File(ConfigService.assetPath).readAsStringSync();
      final config = AppConfig.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );

      expect(config.appName.resolve('ml'), isNot(config.appName.resolve('en')));
      expect(config.details, isNotEmpty);
    });
  });
}

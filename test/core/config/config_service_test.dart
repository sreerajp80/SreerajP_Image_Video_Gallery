import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/config/app_config.dart';
import 'package:in_sreerajp_imgvidgal/core/config/config_service.dart';

void main() {
  group('AppConfig', () {
    test('parses valid json successfully', () {
      final json = {
        'appName': 'Test Gallery',
        'description': 'A test gallery app',
        'version': '1.2.3',
        'build': '42',
        'details': {'Author': 'Test Author', 'License': 'MIT'},
      };

      final config = AppConfig.fromJson(json);

      expect(config.appName, 'Test Gallery');
      expect(config.description, 'A test gallery app');
      expect(config.version, '1.2.3');
      expect(config.build, '42');
      expect(config.details['Author'], 'Test Author');
      expect(config.details['License'], 'MIT');
    });

    test('falls back gracefully on empty or malformed json', () {
      final json = <String, dynamic>{};
      final config = AppConfig.fromJson(json);

      expect(config.appName, AppConfig.fallback.appName);
      expect(config.description, AppConfig.fallback.description);
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
          "appName": "Mock App",
          "description": "Mock Description",
          "version": "2.0.0",
          "build": "10",
          "details": {
            "Custom": "Value"
          }
        }
        ''',
      );

      final config = await service.load();

      expect(config.appName, 'Mock App');
      expect(config.version, '2.0.0');
      expect(config.details['Custom'], 'Value');
    });

    test('returns fallback on asset loading error', () async {
      final service = ConfigService(
        loadAsset: (_) async => throw Exception('Asset missing'),
      );

      final config = await service.load();

      expect(config.appName, AppConfig.fallback.appName);
      expect(config.version, AppConfig.fallback.version);
    });
  });
}

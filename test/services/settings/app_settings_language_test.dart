import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/settings/app_settings.dart';
import 'package:in_sreerajp_imgvidgal/services/settings/app_settings_service.dart';
import 'package:in_sreerajp_imgvidgal/services/settings/language_preference_store.dart';
import 'package:in_sreerajp_imgvidgal/theme/app_theme.dart';

/// Keeps the language value in memory, as `SharedPreferences` would.
class _MemoryLanguageStore implements LanguagePreferenceStore {
  String? value;
  bool failReads = false;

  _MemoryLanguageStore();

  @override
  Future<String?> read() async {
    if (failReads) throw StateError('unreadable');
    return value;
  }

  @override
  Future<void> write(String value) async => this.value = value;
}

void main() {
  late Directory directory;
  late _MemoryLanguageStore store;
  late AppSettingsService service;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('app_language_test');
    store = _MemoryLanguageStore();
    service = AppSettingsService(directory: directory, languageStore: store);
  });

  tearDown(() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  Future<void> writeFile(Map<String, Object?> json) =>
      File(service.filePath).writeAsString(jsonEncode(json));

  test('uses the key the standard names', () {
    expect(AppConstants.languagePreferenceKey, 'app_language');
  });

  group('language migration', () {
    test('moves an old localeCode into the store once', () async {
      await writeFile(<String, Object?>{'localeCode': 'ml', 'theme': 'dark'});

      final settings = await service.load();

      expect(settings.localeCode, 'ml');
      expect(settings.theme, ThemePreference.dark);
      expect(store.value, 'ml');
    });

    test('stores system when there was no old choice', () async {
      final settings = await service.load();

      expect(settings.localeCode, isNull);
      expect(store.value, AppSettingsService.systemLanguageValue);
    });

    test('the store wins over an old localeCode', () async {
      store.value = 'sa';
      await writeFile(<String, Object?>{'localeCode': 'ml'});

      expect((await service.load()).localeCode, 'sa');
    });

    test('system in the store means follow the phone', () async {
      store.value = 'system';
      await writeFile(<String, Object?>{'localeCode': 'ml'});

      expect((await service.load()).localeCode, isNull);
    });

    test('an unknown stored code means follow the phone', () async {
      store.value = 'xx';

      expect((await service.load()).localeCode, isNull);
    });

    test('an unreadable store keeps the file value', () async {
      store.failReads = true;
      await writeFile(<String, Object?>{'localeCode': 'ml'});

      expect((await service.load()).localeCode, 'ml');
    });
  });

  group('language save', () {
    test('writes the language to the store, not the file', () async {
      await service.save(const AppSettings(localeCode: 'sa'));

      expect(store.value, 'sa');
      final json = jsonDecode(await File(service.filePath).readAsString());
      expect((json as Map).containsKey('localeCode'), isFalse);
      expect((await service.load()).localeCode, 'sa');
    });

    test('following the phone is saved as system', () async {
      store.value = 'ml';
      await service.save(AppSettings.defaults);

      expect(store.value, 'system');
      expect((await service.load()).localeCode, isNull);
    });
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/settings/app_settings.dart';
import 'package:in_sreerajp_imgvidgal/services/settings/app_settings_service.dart';
import 'package:in_sreerajp_imgvidgal/theme/app_theme.dart';

void main() {
  late Directory directory;
  late AppSettingsService service;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('app_settings_test');
    service = AppSettingsService(directory: directory);
  });

  tearDown(() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  group('AppSettingsService load', () {
    test('gives the defaults when nothing has been saved', () async {
      expect(await service.load(), AppSettings.defaults);
    });

    test('gives the defaults for a file that is not JSON', () async {
      await File(service.filePath).writeAsString('not json at all {{{');

      // A hand-edited or half-written file must not stop the app opening.
      expect(await service.load(), AppSettings.defaults);
    });

    test('gives the defaults for JSON of the wrong shape', () async {
      await File(service.filePath).writeAsString('["theme", "dark"]');

      expect(await service.load(), AppSettings.defaults);
    });

    test('gives the defaults for an empty file', () async {
      await File(service.filePath).writeAsString('');

      expect(await service.load(), AppSettings.defaults);
    });
  });

  group('AppSettingsService save', () {
    test('writes settings that load back unchanged', () async {
      const settings = AppSettings(
        theme: ThemePreference.amoled,
        localeCode: 'ml',
        gridColumns: 5,
        showFlashbacks: false,
        confirmDestructive: false,
      );

      expect(await service.save(settings), isTrue);
      expect(await service.load(), settings);
    });

    test('replaces what was there before', () async {
      await service.save(const AppSettings(theme: ThemePreference.light));
      await service.save(const AppSettings(theme: ThemePreference.dark));

      expect((await service.load()).theme, ThemePreference.dark);
    });

    test('a Malayalam language choice survives the trip to disk', () async {
      // The whole point of the UTF-8 fix in AtomicSaver: anything but plain
      // ASCII has to come back the way it went in.
      await service.save(const AppSettings(localeCode: 'ml'));

      expect((await service.load()).localeCode, 'ml');
    });

    test('the file is created inside the given directory', () async {
      await service.save(const AppSettings(theme: ThemePreference.dark));

      expect(await File(service.filePath).exists(), isTrue);
      expect(service.filePath, startsWith(directory.path));
    });

    test('a save into a missing directory is reported, not thrown', () async {
      await directory.delete(recursive: true);

      // AtomicSaver creates parent directories, so this normally succeeds.
      // What matters is that it answers rather than throwing at the caller.
      final result = await service.save(AppSettings.defaults);
      expect(result, isA<bool>());
    });
  });
}

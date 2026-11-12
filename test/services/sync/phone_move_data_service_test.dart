import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/backup/backup_manifest.dart';
import 'package:in_sreerajp_imgvidgal/models/backup/backup_payload.dart';
import 'package:in_sreerajp_imgvidgal/models/settings/app_settings.dart';
import 'package:in_sreerajp_imgvidgal/theme/app_theme.dart';
import 'package:in_sreerajp_imgvidgal/services/backup/backup_collector_service.dart';
import 'package:in_sreerajp_imgvidgal/services/backup/backup_serializer.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/phone_move_data_service.dart';

/// Never called: these tests use [PhoneMoveDataService.encode] directly.
class _UnusedCollector implements BackupCollectorService {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('not used by these tests');
}

BackupPayload _payload() => const BackupPayload(
  manifest: BackupManifest(
    payloadVersion: 1,
    schemaVersion: 2,
    appVersion: '1.0.0+1',
    createdAtMs: 1756584284000,
    tagCount: 1,
  ),
  tags: <BackupTag>[
    BackupTag(
      id: 'tag_family',
      name: 'Family',
      colorValue: 0xFF2196F3,
      dateCreatedMs: 1700000000000,
    ),
  ],
);

void main() {
  const serializer = BackupSerializer();
  final service = PhoneMoveDataService(collector: _UnusedCollector());

  group('PhoneMoveDataService', () {
    test('app data and settings survive the trip', () {
      const settings = AppSettings(
        theme: ThemePreference.dark,
        localeCode: 'ml',
        gridColumns: 4,
        secureDelete: true,
      );
      final bytes = PhoneMoveDataService.encode(
        backupJson: serializer.encode(_payload()),
        settings: settings,
      );

      final data = service.decode(bytes);

      expect(data.payload.tags.single.name, 'Family');
      expect(data.settings, settings);
    });

    test('settings are optional', () {
      final bytes = PhoneMoveDataService.encode(
        backupJson: serializer.encode(_payload()),
      );
      expect(service.decode(bytes).settings, isNull);
    });

    test(
      'settings carry preferences only, nothing that belongs to a phone',
      () {
        // Vault PIN, biometrics, permissions and the install id must never be
        // part of what goes to another phone.
        expect(AppSettings.defaults.toJson().keys.toSet(), <String>{
          'theme',
          'localeCode',
          'gridColumns',
          'showFlashbacks',
          'confirmDestructive',
          'protectAllScreens',
          'secureDelete',
        });
      },
    );

    test('a bad settings field falls back, the rest stays', () {
      final envelope = <String, dynamic>{
        'format': PhoneMoveDataService.formatVersion,
        'backup': serializer.encode(_payload()),
        'settings': <String, dynamic>{'theme': 'dark', 'gridColumns': 'many'},
      };
      final bytes = gzip.encode(utf8.encode(jsonEncode(envelope)));

      final settings = service.decode(bytes).settings!;
      expect(settings.theme, ThemePreference.dark);
      expect(settings.gridColumns, AppSettings.defaults.gridColumns);
    });

    test('refuses bytes that are not compressed', () {
      expect(
        () => service.decode(utf8.encode('not gzip at all')),
        throwsA(isA<PhoneMoveDataException>()),
      );
    });

    test('refuses an unknown format', () {
      final bytes = gzip.encode(
        utf8.encode(jsonEncode(<String, dynamic>{'format': 99, 'backup': ''})),
      );
      expect(
        () => service.decode(bytes),
        throwsA(isA<PhoneMoveDataException>()),
      );
    });

    test('refuses a backup that does not parse', () {
      final bytes = gzip.encode(
        utf8.encode(
          jsonEncode(<String, dynamic>{
            'format': PhoneMoveDataService.formatVersion,
            'backup': '{"not": "a backup"}',
          }),
        ),
      );
      expect(
        () => service.decode(bytes),
        throwsA(isA<PhoneMoveDataException>()),
      );
    });
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the settings that keep app data out of cloud backup and
/// device-to-device transfer. These read the source files, so they prove the
/// settings are present, not how Android behaves during a real transfer.
void main() {
  const List<String> domains = <String>[
    'root',
    'file',
    'database',
    'sharedpref',
    'external',
    'device_root',
    'device_file',
    'device_database',
    'device_sharedpref',
  ];

  final String manifest = File(
    'android/app/src/main/AndroidManifest.xml',
  ).readAsStringSync();
  final String rules = File(
    'android/app/src/main/res/xml/data_extraction_rules.xml',
  ).readAsStringSync();

  String section(String name) {
    final Match? match = RegExp(
      '<$name>(.*?)</$name>',
      dotAll: true,
    ).firstMatch(rules);
    expect(match, isNotNull, reason: '<$name> section is missing');
    return match!.group(1)!;
  }

  test('the manifest keeps all three backup settings', () {
    expect(manifest, contains('android:allowBackup="false"'));
    expect(manifest, contains('android:fullBackupContent="false"'));
    expect(
      manifest,
      contains('android:dataExtractionRules="@xml/data_extraction_rules"'),
    );
  });

  for (final String name in <String>['cloud-backup', 'device-transfer']) {
    test('$name excludes every storage area', () {
      final String body = section(name);
      for (final String domain in domains) {
        expect(
          body,
          contains('<exclude domain="$domain" path="." />'),
          reason: '$name does not exclude $domain',
        );
      }
      expect(body, isNot(contains('<include')));
    });
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The launcher name of the prod build must match `appName` in
/// `app_config.json` for every language (guideline.md §1.8). These read the
/// source files; they do not show what a phone's launcher displays.
void main() {
  final Map<String, dynamic> appName =
      (jsonDecode(File('assets/config/app_config.json').readAsStringSync())
              as Map<String, dynamic>)['appName']
          as Map<String, dynamic>;

  String launcherName(String folder) {
    final String xml = File(
      'android/app/src/prod/res/$folder/strings.xml',
    ).readAsStringSync();
    return RegExp(
      r'<string name="app_name">([^<]*)</string>',
    ).firstMatch(xml)!.group(1)!;
  }

  const Map<String, String> folders = <String, String>{
    'en': 'values',
    'ml': 'values-ml',
    'sa': 'values-sa',
  };

  for (final MapEntry<String, String> entry in folders.entries) {
    test('prod launcher name matches appName in ${entry.key}', () {
      expect(launcherName(entry.value), appName[entry.key]);
    });
  }

  test('every dev launcher name ends with Dev', () {
    for (final String folder in folders.values) {
      final String xml = File(
        'android/app/src/dev/res/$folder/strings.xml',
      ).readAsStringSync();
      expect(xml, contains(' Dev</string>'), reason: folder);
    }
  });
}

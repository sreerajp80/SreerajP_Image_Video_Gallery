import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/services/platform/share_service.dart';

/// Guards how much the file provider can hand to other apps. These read the
/// source files, so they prove the settings are present, not how Android
/// behaves when sharing on a phone.
void main() {
  final String paths = File(
    'android/app/src/main/res/xml/provider_paths.xml',
  ).readAsStringSync();
  final String handler = File(
    'android/app/src/main/kotlin/in/sreerajp/imgvidgal/tools/IntentChannelHandler.kt',
  ).readAsStringSync();

  test('the provider exposes only the share folder', () {
    final List<RegExpMatch> entries = RegExp(
      r'<([a-z-]+-path)\s[^>]*path="([^"]*)"',
    ).allMatches(paths).toList();

    expect(entries, hasLength(1));
    expect(entries.single.group(1), 'cache-path');
    expect(entries.single.group(2), '${ShareService.shareFolderName}/');
  });

  test('the Kotlin handler checks the same folder', () {
    expect(
      handler,
      contains('const val SHARE_FOLDER = "${ShareService.shareFolderName}"'),
    );
    expect(handler, contains('startsWith(shareRoot.path + File.separator)'));
  });
}

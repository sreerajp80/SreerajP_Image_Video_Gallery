import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The dependency rules in CLAUDE.md, checked on the whole tree.
///
/// A package's own dependency list is not enough. On 2026-11-02 a barcode
/// package looked clean until `pub get` showed it pulling in `http` through
/// `image_picker`. This test reads the full lock file, so that cannot happen
/// again unnoticed.
void main() {
  final lock = File('pubspec.lock').readAsStringSync();
  final pubspec = File('pubspec.yaml').readAsStringSync();
  final gradle = File('android/app/build.gradle.kts').readAsStringSync();

  test('no blocked package anywhere in the lock file', () {
    final locked = RegExp(
      r'^  ([a-z0-9_]+):$',
      multiLine: true,
    ).allMatches(lock).map((m) => m.group(1)!);
    final blocked = RegExp(
      r'^(http|dio|firebase\w*|cloud_\w+|supabase\w*|google_mlkit\w*|'
      r'connectivity\w*|sentry\w*|\w*analytics\w*|\w*crashlytics\w*|'
      r'google_mobile_ads|mobile_scanner)$',
    );
    final found = locked.where(blocked.hasMatch).toList();
    expect(found, isEmpty, reason: 'Blocked packages: ${found.join(', ')}');
  });

  test('mobile_scanner (Google ML Kit) is not a dependency', () {
    expect(
      pubspec,
      isNot(contains(RegExp(r'^\s*mobile_scanner:', multiLine: true))),
    );
  });

  test('the Android build pulls in no ML Kit or Play Services library', () {
    final lines = gradle
        .split('\n')
        .where((line) => line.trim().startsWith('implementation('));
    for (final line in lines) {
      expect(line, isNot(contains('com.google.mlkit')), reason: line);
      expect(line, isNot(contains('com.google.android.gms')), reason: line);
      expect(line, isNot(contains('firebase')), reason: line);
    }
  });

  test('app code never fetches remote content', () {
    final remote = RegExp(
      r'NetworkAssetBundle|NetworkImage|Image\.network|HttpClient\(|'
      r'readBarcodeImageUrl',
    );
    final hits = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (remote.hasMatch(lines[i])) hits.add('${entity.path}:${i + 1}');
      }
    }
    expect(hits, isEmpty, reason: hits.join('\n'));
  });
}

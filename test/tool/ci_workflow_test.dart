import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// CI only runs checks (CLAUDE.md workflow rule 5, standard 19.1). These
/// read the workflow file, so a later edit cannot quietly add a build, a
/// secret or a write permission.
void main() {
  final workflow = File('.github/workflows/ci.yml').readAsStringSync();
  final claude = File('CLAUDE.md').readAsStringSync();

  test('runs on pull requests and on pushes to master', () {
    expect(workflow, contains('pull_request:'));
    expect(workflow, contains('branches: [master]'));
  });

  test('has read-only permission and uses no secrets', () {
    expect(workflow, contains('contents: read'));
    expect(workflow, isNot(contains('secrets.')));
    expect(workflow, isNot(contains(': write')));
  });

  test('never builds, signs, uploads or publishes', () {
    for (final banned in <String>[
      'flutter build',
      'upload-artifact',
      'keystore',
      'key.properties',
      'gradlew',
      'publish',
    ]) {
      expect(workflow, isNot(contains(banned)), reason: banned);
    }
  });

  test('runs the required checks', () {
    for (final step in <String>[
      'flutter pub get',
      'dart format --output=none --set-exit-if-changed .',
      'flutter analyze',
      'flutter test',
    ]) {
      expect(workflow, contains(step), reason: step);
    }
  });

  test('pins the same Flutter version as CLAUDE.md', () {
    final pinned = RegExp(r'flutter-version:\s*(\S+)').firstMatch(workflow);
    expect(pinned, isNotNull);
    expect(claude, contains('**${pinned!.group(1)}** (stable)'));
  });
}

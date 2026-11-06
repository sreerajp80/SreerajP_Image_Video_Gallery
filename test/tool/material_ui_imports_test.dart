import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The app uses the maintained `material_ui` / `cupertino_ui` packages, never
/// the frozen copies inside the SDK (engineering standard 6.1, G22). Mixing
/// the two would split the theme and localizations between two libraries.
void main() {
  test('no code imports the SDK Material or Cupertino library', () {
    final sdkImport = RegExp(
      r'''import\s+['"]package:flutter/(material|cupertino)\.dart['"]''',
    );
    final hits = <String>[];
    for (final folder in <String>['lib', 'test']) {
      for (final entity in Directory(folder).listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path.contains('${Platform.pathSeparator}generated')) {
          continue;
        }
        if (sdkImport.hasMatch(entity.readAsStringSync())) {
          hits.add(entity.path);
        }
      }
    }
    expect(hits, isEmpty, reason: hits.join('\n'));
  });

  test('material_ui and cupertino_ui are declared with a caret', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(
      pubspec,
      contains(RegExp(r'^\s*material_ui:\s*\^', multiLine: true)),
    );
    expect(
      pubspec,
      contains(RegExp(r'^\s*cupertino_ui:\s*\^', multiLine: true)),
    );
  });
}

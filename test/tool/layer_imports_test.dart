import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The dependency direction from CLAUDE.md:
/// screens → providers → repositories/services → database/platform → models.
/// UI reaches services only through providers (G46). Pure, I/O-free rules
/// live in lib/core/domain/ and may be used anywhere.
void main() {
  const pkg = 'package:in_sreerajp_imgvidgal/';

  List<String> offenders(List<String> folders, List<String> banned) {
    final hits = <String>[];
    for (final folder in folders) {
      for (final entity in Directory(folder).listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final source = entity.readAsStringSync();
        for (final layer in banned) {
          if (source.contains("import '$pkg$layer/")) {
            hits.add('${entity.path} imports $layer/');
          }
        }
      }
    }
    return hits;
  }

  test('screens and widgets never import services or repositories', () {
    final hits = offenders(
      <String>['lib/screens', 'lib/widgets'],
      <String>['services', 'repositories'],
    );
    expect(hits, isEmpty, reason: hits.join('\n'));
  });

  test('models import no higher layer', () {
    final hits = offenders(
      <String>['lib/models'],
      <String>['services', 'repositories', 'providers', 'screens', 'widgets'],
    );
    expect(hits, isEmpty, reason: hits.join('\n'));
  });

  test('pure domain rules import no service, provider or UI', () {
    final hits = offenders(
      <String>['lib/core/domain'],
      <String>['services', 'repositories', 'providers', 'screens', 'widgets'],
    );
    expect(hits, isEmpty, reason: hits.join('\n'));
  });
}

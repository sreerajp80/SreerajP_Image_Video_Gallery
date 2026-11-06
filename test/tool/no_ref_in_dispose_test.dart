import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Riverpod 3 does not allow a widget to use `ref` inside `dispose()`, and
/// the call does not run. Clean-up there (closing the transfer port, giving
/// back the screen-protection request) must use a value read in `initState`.
/// Found on 2026-11-02; this keeps it from coming back.
void main() {
  test('no dispose() in lib/ uses ref', () {
    final hits = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();
      for (final match in RegExp(r'void dispose\(\)\s*\{').allMatches(source)) {
        var depth = 1;
        var i = match.end;
        while (depth > 0 && i < source.length) {
          if (source[i] == '{') depth++;
          if (source[i] == '}') depth--;
          i++;
        }
        final body = source.substring(match.end, i);
        if (RegExp(r'\bref\.(read|watch|listen|invalidate)\b').hasMatch(body)) {
          final line = '\n'.allMatches(source.substring(0, match.start)).length;
          hits.add('${entity.path}:${line + 1}');
        }
      }
    }
    expect(hits, isEmpty, reason: hits.join('\n'));
  });
}

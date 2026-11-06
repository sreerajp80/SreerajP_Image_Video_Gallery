import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// No silent catches in services and repositories (engineering standard
/// §11.2, §14.5).
///
/// Every `catch` block in `lib/services/` and `lib/repositories/` must do at
/// least one of these:
/// - rethrow, or throw a typed error;
/// - log through `AppLogger` (never a path, name or metadata value);
/// - carry a `// Safe to ignore: <reason>` comment saying why silence is
///   right, for best-effort work such as deleting a temporary file.
void main() {
  const folders = <String>['lib/services', 'lib/repositories'];
  final allowed = RegExp(
    r'\brethrow\b|\bthrow\b|AppLogger\.|// Safe to ignore:',
  );
  final catchStart = RegExp(r'\bcatch\s*\([^)]*\)\s*\{');

  /// Returns the body of the block that opens just before [from].
  String blockBody(String source, int from) {
    var depth = 1;
    var i = from;
    while (depth > 0 && i < source.length) {
      final char = source[i];
      if (char == '{') depth++;
      if (char == '}') depth--;
      i++;
    }
    return source.substring(from, i - 1);
  }

  test('every catch block rethrows, logs, or says why it is safe', () {
    final problems = <String>[];
    for (final folder in folders) {
      final files = Directory(folder)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));
      for (final file in files) {
        final source = file.readAsStringSync();
        for (final match in catchStart.allMatches(source)) {
          final body = blockBody(source, match.end);
          if (allowed.hasMatch(body)) continue;
          final line = '\n'.allMatches(source.substring(0, match.start)).length;
          problems.add('${file.path.replaceAll(r'\', '/')}:${line + 1}');
        }
      }
    }
    expect(
      problems,
      isEmpty,
      reason: '${problems.length} silent catch blocks:\n${problems.join('\n')}',
    );
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Sanskrit must be Sanskrit, not Hindi in Devanagari (engineering standard
/// §8.5.1). This is the CI gate from that section, ported to Dart so it runs
/// with `flutter test`. Passing it is a smoke test, not a proof: the
/// Sanskrit still needs review by a fluent reader.
void main() {
  // Standalone words match only between word edges; the rest match anywhere.
  const edgeBefore = r'''(?:^|(?<=[\s"'(\[{<>।,*_`#|:;~-]))''';
  const edgeAfter = r'''(?=[\s"')\]}<>।,.?!*_`#|:;~-]|$)''';
  final hindi = RegExp(
    '$edgeBefore(?:था|थे|थी|हो|है|हैं|हूं|और)$edgeAfter'
    '|करें|करना|करके|रहा|रही|रहे|गया|गयी|चाहिए'
    '|नहीं|लेकिन|क्या|कृपया|सेटिंग्स|ऐप'
    '|़|[क़-य़]',
    multiLine: true,
  );

  /// Sanskrit words that contain a marker's letters inside them, so the
  /// language pack's gate (which matches `क्या` and `रहा` anywhere) flags them.
  /// The owner checked each one on 2026-11-05: `अशक्या…` is अ + शक्या ("not
  /// possible") and `सङ्ग्रहान्वेषणम्` is सङ्ग्रह + अन्वेषणम्. Only the named token
  /// is excused, and only in the named key. Recorded in `docs/known_gaps.md`
  /// §3; the request to match these tokens as whole words is in
  /// `plans/20261105_073420_apply-sanskrit-review.md` §8.
  const sanskritInsideMarker = <String, String>{
    'errorEditorSaveFailed': 'क्या',
    'errorConvertFailed': 'क्या',
    'errorBackupFailed': 'क्या',
    'errorRestoreFailed': 'क्या',
    'errorNotesSaveFailed': 'क्या',
    'bodyPdfSkippedCount': 'क्या',
    'bodyCleanerFailures': 'क्या',
    'titleSearchStart': 'रहा',
  };
  final arbKey = RegExp(r'^\s*"(\w+)"\s*:');

  test('the pattern still catches a Hindi copula (self-test)', () {
    for (final sample in <String>[
      '"greeting": "है"',
      '<b>है</b>',
      'यह **है**',
      'यह `है`',
      'वह *था*',
      'सेटिंग्स',
      'क़',
    ]) {
      expect(hindi.hasMatch(sample), isTrue, reason: sample);
    }
  });

  test('the pattern leaves real Sanskrit alone (self-test)', () {
    for (final sample in <String>[
      'स्थाप्यताम्',
      'स्थानम्',
      'पुनःस्थाप्यताम्',
      'यथा',
      'तथा',
      'कथा',
    ]) {
      expect(hindi.hasMatch(sample), isFalse, reason: sample);
    }
  });

  for (final path in <String>[
    'lib/l10n/app_sa.arb',
    'assets/config/app_config.json',
  ]) {
    test('$path has no Hindi markers', () {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: 'every app ships $path');

      final problems = <String>[];
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final key = arbKey.firstMatch(lines[i])?.group(1);
        final excused = path.endsWith('.arb')
            ? sanskritInsideMarker[key]
            : null;
        for (final match in hindi.allMatches(lines[i])) {
          if (match.group(0) == excused) continue;
          problems.add('$path:${i + 1}: "${match.group(0)}" in ${lines[i]}');
        }
      }
      expect(problems, isEmpty, reason: problems.join('\n'));
    });
  }

  test('every excused key still needs its exception', () {
    final lines = File('lib/l10n/app_sa.arb').readAsLinesSync();
    final stale = <String>[];
    sanskritInsideMarker.forEach((key, token) {
      final line = lines.firstWhere(
        (l) => arbKey.firstMatch(l)?.group(1) == key,
        orElse: () => '',
      );
      if (!line.contains(token)) stale.add(key);
    });
    expect(stale, isEmpty, reason: 'remove from sanskritInsideMarker: $stale');
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// The OCR accuracy tool lives outside lib/, so it cannot be reached with a
// package: import.
import '../../../tool/ocr_eval/src/sample.dart';

void main() {
  group('names', () {
    test('group is the first two parts of the name', () {
      expect(groupOf('ml_newspaper_03'), 'ml_newspaper');
      expect(groupOf('en_dark_1'), 'en_dark');
      expect(groupOf('single'), 'single');
    });

    test('language comes from the first part', () {
      expect(languageOf('en_screenshot_01'), 'eng');
      expect(languageOf('ml_print_01'), 'mal');
      expect(languageOf('mixed_example_01'), 'eng+mal');
      expect(languageOf('fr_print_01'), isNull);
    });
  });

  group('findSamples', () {
    late Directory folder;

    setUp(() => folder = Directory.systemTemp.createTempSync('ocr_eval_'));
    tearDown(() => folder.deleteSync(recursive: true));

    void touch(String name) => File(
      '${folder.path}${Platform.pathSeparator}$name',
    ).writeAsStringSync('x');

    test('pairs pictures with their correct text, in name order', () {
      touch('en_doc_02.png');
      touch('en_doc_02.gt.txt');
      touch('en_doc_01.JPG');
      touch('en_doc_01.gt.txt');

      final found = findSamples(folder);

      expect(found.samples.map((s) => s.name), <String>[
        'en_doc_01',
        'en_doc_02',
      ]);
      expect(found.missingTruth, isEmpty);
    });

    test('reports a picture with no correct text', () {
      touch('ml_print_01.png');

      final found = findSamples(folder);

      expect(found.samples, isEmpty);
      expect(found.missingTruth, <String>['ml_print_01.png']);
    });

    test('ignores other files', () {
      touch('README.md');
      touch('notes.txt');

      final found = findSamples(folder);

      expect(found.samples, isEmpty);
      expect(found.missingTruth, isEmpty);
    });
  });
}

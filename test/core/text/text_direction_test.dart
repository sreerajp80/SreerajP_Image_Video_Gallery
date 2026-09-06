import 'package:flutter/widgets.dart' show TextDirection;
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/text/text_direction.dart';

void main() {
  group('detectTextDirection', () {
    test('reads English left to right', () {
      expect(detectTextDirection('A note about the trip'), TextDirection.ltr);
    });

    test('reads Malayalam left to right', () {
      // Malayalam is one of the app's two languages and reads left to right,
      // like English. It must never be mistaken for a right-to-left script.
      expect(detectTextDirection('മലയാളം കുറിപ്പ്'), TextDirection.ltr);
    });

    test('reads Arabic right to left', () {
      expect(detectTextDirection('مرحبا بالعالم'), TextDirection.rtl);
    });

    test('reads Hebrew right to left', () {
      expect(detectTextDirection('שלום עולם'), TextDirection.rtl);
    });

    test('gives no answer for an empty string', () {
      expect(detectTextDirection(''), isNull);
    });

    test('gives no answer for spaces alone', () {
      expect(detectTextDirection('   \n\t '), isNull);
    });

    test('gives no answer for digits alone', () {
      // A file name that is only a number has no direction to take from.
      expect(detectTextDirection('20260831'), isNull);
    });

    test('gives no answer for punctuation alone', () {
      expect(detectTextDirection('--- ... !?'), isNull);
    });

    test('skips leading digits and takes the first real word', () {
      // A note starting with a number must still follow the word after it,
      // in either direction.
      expect(detectTextDirection('2026 مرحبا'), TextDirection.rtl);
      expect(detectTextDirection('2026 notes'), TextDirection.ltr);
    });

    test('skips a leading emoji', () {
      expect(detectTextDirection('📷 مرحبا'), TextDirection.rtl);
      expect(detectTextDirection('📷 holiday'), TextDirection.ltr);
    });

    test('skips leading punctuation and symbols', () {
      expect(detectTextDirection('- "מזל"'), TextDirection.rtl);
      expect(detectTextDirection('→ trip'), TextDirection.ltr);
    });

    test('takes the first strong character, not the majority', () {
      // The Unicode rule is first-strong, not a head count. An English
      // sentence quoting one Arabic word stays left to right.
      expect(
        detectTextDirection('The sign said مرحبا at the door'),
        TextDirection.ltr,
      );
      // And the mirror case.
      expect(detectTextDirection('مرحبا everyone'), TextDirection.rtl);
    });

    test('handles other left-to-right scripts', () {
      expect(detectTextDirection('こんにちは'), TextDirection.ltr);
      expect(detectTextDirection('Привет'), TextDirection.ltr);
      expect(detectTextDirection('नमस्ते'), TextDirection.ltr);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';

// The OCR accuracy tool lives outside lib/, so it cannot be reached with a
// package: import.
import '../../../tool/ocr_eval/src/error_rate.dart';

void main() {
  group('editDistance', () {
    test('is zero for equal lists', () {
      expect(editDistance(<String>['a', 'b'], <String>['a', 'b']), 0);
    });

    test('counts one substitution, insertion and deletion', () {
      expect(editDistance(<String>['a', 'b', 'c'], <String>['a', 'x', 'c']), 1);
      expect(editDistance(<String>['a', 'c'], <String>['a', 'b', 'c']), 1);
      expect(editDistance(<String>['a', 'b', 'c'], <String>['a', 'c']), 1);
    });

    test('equals the other length when one side is empty', () {
      expect(editDistance(const <String>[], <String>['a', 'b']), 2);
      expect(editDistance(<String>['a', 'b', 'c'], const <String>[]), 3);
    });

    test('gives the classic kitten / sitting distance', () {
      expect(editDistance('kitten'.split(''), 'sitting'.split('')), 3);
    });
  });

  group('measureErrorRate', () {
    test('is zero for identical text', () {
      final rate = measureErrorRate(
        truth: 'hello world',
        result: 'hello world',
      );
      expect(rate.cer, 0);
      expect(rate.wer, 0);
    });

    test('one wrong letter in ten gives 10% CER and one wrong word', () {
      final rate = measureErrorRate(truth: 'abcde fghi', result: 'abcde fgxi');
      expect(rate.truthCharacters, 10);
      expect(rate.cer, closeTo(0.1, 1e-9));
      expect(rate.truthWords, 2);
      expect(rate.wer, closeTo(0.5, 1e-9));
    });

    test('counts a Malayalam conjunct as one character', () {
      // ക്ഷ is three code points but one unit a reader sees.
      final rate = measureErrorRate(truth: 'ക്ഷമ', result: 'ക്ഷമ');
      expect(rate.truthCharacters, 2);
      expect(rate.cer, 0);
    });

    test('a misread conjunct is one mistake, not several', () {
      // ക്ഷ read as ക (the virama and ഷ lost): one unit wrong out of two.
      final rate = measureErrorRate(truth: 'ക്ഷമ', result: 'കമ');
      expect(rate.cer, closeTo(0.5, 1e-9));
    });

    test('empty truth with no output is perfect', () {
      final rate = measureErrorRate(truth: '', result: '');
      expect(rate.cer, 0);
      expect(rate.wer, 0);
    });

    test(
      'empty truth with output is fully wrong, without dividing by zero',
      () {
        final rate = measureErrorRate(truth: '', result: 'noise');
        expect(rate.cer, 1);
        expect(rate.wer, 1);
      },
    );

    test('no output against real text is fully wrong', () {
      final rate = measureErrorRate(truth: 'two words', result: '');
      expect(rate.cer, 1);
      expect(rate.wer, 1);
    });
  });
}

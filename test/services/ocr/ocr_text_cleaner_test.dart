import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/services/ocr/ocr_text_cleaner.dart';

const _cleaner = OcrTextCleaner();

void main() {
  group('empty input', () {
    test('nothing in, nothing out', () {
      expect(_cleaner.clean(''), '');
      expect(_cleaner.cleanLines(''), isEmpty);
      expect(_cleaner.cleanLines('   \n\n   '), isEmpty);
    });
  });

  group('tidying', () {
    test('trailing and leading spaces come off each line', () {
      expect(_cleaner.cleanLines('  hello  \n  world  '), <String>[
        'hello',
        'world',
      ]);
    });

    test('runs of spaces inside a line collapse to one', () {
      expect(_cleaner.clean('a      b     c'), 'a b c');
    });

    test('tabs are treated as spaces', () {
      expect(_cleaner.clean('a\t\tb'), 'a b');
    });

    test('blank lines are dropped', () {
      expect(_cleaner.cleanLines('one\n\n\n\ntwo'), <String>['one', 'two']);
    });

    test('windows line endings are handled', () {
      expect(_cleaner.cleanLines('one\r\ntwo'), <String>['one', 'two']);
    });

    test('exotic spaces become plain ones', () {
      expect(_cleaner.clean('a b c'), 'a b c');
    });

    test('zero-width characters are removed', () {
      expect(_cleaner.clean('he​llo'), 'hello');
    });
  });

  group('reading order is never changed', () {
    test('lines come back in the order they were read', () {
      const raw = 'Invoice\nDate: 2026-08-31\nTotal: 450.00';
      expect(_cleaner.cleanLines(raw), <String>[
        'Invoice',
        'Date: 2026-08-31',
        'Total: 450.00',
      ]);
    });

    test('no word is corrected, however wrong it looks', () {
      expect(_cleaner.clean('teh qu1ck br0wn f0x'), 'teh qu1ck br0wn f0x');
    });

    test('punctuation is left alone', () {
      const raw = 'Dr. Menon (MBBS) - 9 a.m.';
      expect(_cleaner.clean(raw), raw);
    });
  });

  group('stray marks', () {
    test('a short line of specks is dropped', () {
      expect(_cleaner.cleanLines('real text\n.\n~\n--'), <String>['real text']);
    });

    // Cautious on purpose: a wrongly dropped line is one the user cannot
    // get back, so anything with a letter or digit in it stays.
    test('a short line with a letter or digit is kept', () {
      expect(_cleaner.cleanLines('a'), <String>['a']);
      expect(_cleaner.cleanLines('7'), <String>['7']);
      expect(_cleaner.cleanLines('No.'), <String>['No.']);
      expect(_cleaner.cleanLines('ക'), <String>['ക']);
    });

    test('a long line of punctuation is kept', () {
      expect(_cleaner.cleanLines('-----------'), <String>['-----------']);
    });
  });

  group('malayalam', () {
    test('malayalam text passes through unchanged', () {
      const malayalam = 'കോവളം കടപ്പുറം';
      expect(_cleaner.clean(malayalam), malayalam);
    });

    test('mixed english and malayalam keeps both', () {
      const mixed = 'Beach: കോവളം';
      expect(_cleaner.clean(mixed), mixed);
    });

    test('malayalam lines are not read as noise', () {
      expect(_cleaner.cleanLines('ഒന്ന്\nരണ്ട്'), hasLength(2));
    });
  });
}

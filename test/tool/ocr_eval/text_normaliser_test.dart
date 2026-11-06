import 'package:flutter_test/flutter_test.dart';

// The OCR accuracy tool lives outside lib/, so it cannot be reached with a
// package: import.
import '../../../tool/ocr_eval/src/text_normaliser.dart';

void main() {
  const normaliser = TextNormaliser();

  test('collapses spaces and line breaks, and trims', () {
    expect(
      normaliser.normalise('  one   two\r\nthree\n\n four  '),
      'one two three four',
    );
  });

  test('turns every old chillu spelling into the single letter', () {
    const zwj = '\u200D';
    expect(normaliser.normalise('ണ്$zwj'), 'ൺ');
    expect(normaliser.normalise('ന്$zwj'), 'ൻ');
    expect(normaliser.normalise('ര്$zwj'), 'ർ');
    expect(normaliser.normalise('ല്$zwj'), 'ൽ');
    expect(normaliser.normalise('ള്$zwj'), 'ൾ');
    expect(normaliser.normalise('ക്$zwj'), 'ൿ');
  });

  test('old and new chillu spellings compare equal', () {
    expect(
      normaliser.normalise('കുട്ടികള്\u200D'),
      normaliser.normalise('കുട്ടികൾ'),
    );
  });

  test('composes two-part vowel signs', () {
    expect(normaliser.normalise('ക\u0D46\u0D3E'), 'ക\u0D4A');
    expect(normaliser.normalise('ക\u0D47\u0D3E'), 'ക\u0D4B');
    expect(normaliser.normalise('ക\u0D46\u0D57'), 'ക\u0D4C');
  });

  test('drops leftover joiners', () {
    expect(normaliser.normalise('ക്\u200Cക'), 'ക്ക');
  });

  test('leaves a plain virama without a joiner alone', () {
    // ന് at the end of a word is a real spelling, not a chillu.
    expect(normaliser.normalise('ഇന്ന്'), 'ഇന്ന്');
  });

  test('leaves English text unchanged apart from spacing', () {
    expect(
      normaliser.normalise('Invoice No. 2041, Total: 318.50'),
      'Invoice No. 2041, Total: 318.50',
    );
  });
}

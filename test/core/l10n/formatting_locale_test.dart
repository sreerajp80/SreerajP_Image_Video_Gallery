import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/l10n/formatting_locale.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

void main() {
  setUpAll(() async {
    // In the app, flutter_localizations loads this data.
    await initializeDateFormatting();
  });

  test('English and Malayalam are passed through', () {
    expect(formattingLocale(const Locale('en')), 'en');
    expect(formattingLocale(const Locale('ml')), 'ml');
  });

  test('Sanskrit falls back to English, never Hindi', () {
    expect(formattingLocale(const Locale('sa')), 'en');
  });

  test('a region tag falls back to its language when needed', () {
    expect(
      formattingLocale(const Locale('ml', 'IN')),
      anyOf('ml-IN', 'ml_IN', 'ml'),
    );
  });

  test('the result always works with DateFormat', () {
    for (final code in <String>['en', 'ml', 'sa']) {
      final locale = formattingLocale(Locale(code));
      expect(
        () => DateFormat.yMMMd(locale).format(DateTime(2026, 9, 26)),
        returnsNormally,
        reason: code,
      );
    }
  });
}

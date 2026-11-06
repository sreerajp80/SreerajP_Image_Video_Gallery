import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// The languages the app declares (`docs/PROJECT_PROFILE.md`).
///
/// Engineering standard §8.7: a screen's widget tests run in every one of
/// them, asserting no overflow and no English text leaking through.
const List<Locale> declaredLocales = <Locale>[
  Locale('en'),
  Locale('ml'),
  Locale('sa'),
];

final Map<String, Set<String>> _leakCache = <String, Set<String>>{};

/// English strings that must not appear on screen under [languageCode].
///
/// A string is left out when the other language uses the very same text
/// (brand names, symbols), and when it has a placeholder, since the shown
/// text then differs from the ARB value anyway.
Set<String> _englishOnly(String languageCode) {
  return _leakCache.putIfAbsent(languageCode, () {
    Map<String, dynamic> read(String code) =>
        jsonDecode(File('lib/l10n/app_$code.arb').readAsStringSync())
            as Map<String, dynamic>;
    final english = read('en');
    final other = read(languageCode);
    return <String>{
      for (final entry in english.entries)
        if (!entry.key.startsWith('@') &&
            entry.value is String &&
            !(entry.value as String).contains('{') &&
            other[entry.key] != entry.value)
          (entry.value as String).trim(),
    };
  });
}

/// Checks the screen now on [tester] for the problems §8.7 and §7.8 name.
///
/// - No exception was raised while it was built (an overflow is one).
/// - Under a language other than English, no visible text is an English
///   string the other language translates.
/// - Every icon button and floating button has a tooltip.
void expectLocaleClean(WidgetTester tester, Locale locale) {
  expect(tester.takeException(), isNull, reason: 'error in $locale');

  if (locale.languageCode != 'en') {
    final leaks = _englishOnly(locale.languageCode);
    final shown = tester
        .widgetList<RichText>(find.byType(RichText))
        .map((text) => text.text.toPlainText().trim())
        .where(leaks.contains)
        .toList();
    expect(shown, isEmpty, reason: 'English text under $locale');
  }

  for (final button in tester.widgetList<IconButton>(find.byType(IconButton))) {
    expect(
      button.tooltip?.trim().isNotEmpty ?? false,
      isTrue,
      reason: 'IconButton ${button.icon} has no tooltip in $locale',
    );
  }
  for (final fab in tester.widgetList<FloatingActionButton>(
    find.byType(FloatingActionButton),
  )) {
    expect(
      fab.tooltip?.trim().isNotEmpty ?? false,
      isTrue,
      reason: 'FloatingActionButton has no tooltip in $locale',
    );
  }
}

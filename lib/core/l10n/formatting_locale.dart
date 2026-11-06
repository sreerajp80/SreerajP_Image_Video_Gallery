import 'dart:ui' show Locale;

import 'package:intl/intl.dart';

/// The locale to hand to `intl` for dates and numbers.
///
/// `intl` has no Sanskrit data, so `DateFormat.yMMMd('sa')` throws. Sanskrit
/// is formatted with English patterns while the words around it stay
/// Sanskrit. Never fall back to Hindi (engineering standard §8.3.2).
String formattingLocale(Locale locale) {
  final tag = locale.toLanguageTag();
  if (DateFormat.localeExists(tag)) return tag;
  if (DateFormat.localeExists(locale.languageCode)) {
    return locale.languageCode;
  }
  return 'en';
}

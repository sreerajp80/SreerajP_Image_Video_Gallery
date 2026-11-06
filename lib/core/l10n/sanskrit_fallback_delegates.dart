import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
// Only the widgets text comes from flutter_localizations. The Material and
// Cupertino text must come from material_ui / cupertino_ui, whose
// MaterialApp looks up their own localization types (G22).
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';

/// Flutter ships no Material, Cupertino or Widgets text for Sanskrit (`sa`).
///
/// Without these delegates the first date picker, dialog or text-selection
/// menu under `sa` throws. They answer for `sa` with the English framework
/// text, so those widgets work while the app's own strings stay Sanskrit.
/// English, never Hindi, so no Hindi can leak into a Sanskrit screen
/// (engineering standard §8.3.1).
class SaMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const SaMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'sa';

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      GlobalMaterialLocalizations.delegate.load(const Locale('en'));

  @override
  bool shouldReload(covariant LocalizationsDelegate<Object?> old) => false;
}

/// Cupertino framework text for `sa`, served in English. See above.
class SaCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const SaCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'sa';

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      GlobalCupertinoLocalizations.delegate.load(const Locale('en'));

  @override
  bool shouldReload(covariant LocalizationsDelegate<Object?> old) => false;
}

/// Widgets framework text for `sa`, served in English. See above.
class SaWidgetsLocalizationsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const SaWidgetsLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'sa';

  @override
  Future<WidgetsLocalizations> load(Locale locale) =>
      GlobalWidgetsLocalizations.delegate.load(const Locale('en'));

  @override
  bool shouldReload(covariant LocalizationsDelegate<Object?> old) => false;
}

/// Every delegate the app needs, Sanskrit fallbacks first so they win for
/// `sa`. Use this wherever a `MaterialApp` is built, including tests.
const List<LocalizationsDelegate<Object?>> appLocalizationsDelegates =
    <LocalizationsDelegate<Object?>>[
      AppLocalizations.delegate,
      SaMaterialLocalizationsDelegate(),
      SaCupertinoLocalizationsDelegate(),
      SaWidgetsLocalizationsDelegate(),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ];

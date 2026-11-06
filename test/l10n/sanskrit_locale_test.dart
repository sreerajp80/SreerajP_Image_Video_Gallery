import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/config/app_config.dart';
import 'package:in_sreerajp_imgvidgal/core/l10n/sanskrit_fallback_delegates.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/providers/settings_providers.dart';
import 'package:in_sreerajp_imgvidgal/screens/settings/about_screen.dart';
import 'package:flutter_riverpod/misc.dart';

/// Flutter has no framework text for Sanskrit, so the first date picker or
/// dialog under `sa` is the most likely Sanskrit crash (§8.3.1).
void main() {
  Widget app(Widget home) => MaterialApp(
    locale: const Locale('sa'),
    localizationsDelegates: appLocalizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );

  testWidgets('sa is a supported locale', (tester) async {
    expect(
      AppLocalizations.supportedLocales.map((l) => l.languageCode),
      containsAll(<String>['en', 'ml', 'sa']),
    );
  });

  testWidgets('a date picker and a dialog open under sa', (tester) async {
    late BuildContext captured;
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) {
            captured = context;
            return Scaffold(
              body: Text(AppLocalizations.of(context)!.titleSettings),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The app's own strings are Sanskrit.
    expect(find.text('विन्यासः'), findsOneWidget);

    showDatePicker(
      context: captured,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDate: DateTime(2026, 9, 26),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(DatePickerDialog), findsOneWidget);
    Navigator.of(captured).pop();
    await tester.pumpAndSettle();

    showDialog<void>(
      context: captured,
      builder: (_) => const AlertDialog(content: Text('x')),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('the About screen renders in Sanskrit with the badge', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          appConfigProvider.overrideWith(
            (ref) async => const AppConfig(
              appName: LocalizedText.byLocale(<String, String>{
                'en': 'Gallery',
                'sa': 'चित्रशाला',
              }),
              description: LocalizedText.plain('-'),
              version: '1.0.0',
              build: '1',
              details: <String, LocalizedText>{
                'author': LocalizedText.byLocale(<String, String>{
                  'en': 'Sreeraj P',
                  'sa': 'श्रीराजः पी',
                }),
              },
            ),
          ),
        ],
        child: app(const AboutScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('चित्रशाला'), findsOneWidget);
    expect(find.text('लेखकः'), findsOneWidget);
    expect(find.text('श्रीराजः पी'), findsOneWidget);
    expect(find.bySemanticsLabel('सस्नेहं निर्मितम् भारततः'), findsOneWidget);
  });
}

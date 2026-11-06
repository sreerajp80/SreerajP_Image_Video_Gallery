import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/config/app_config.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/build_date.g.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/providers/settings_providers.dart';
import 'package:in_sreerajp_imgvidgal/screens/settings/about_screen.dart';
import 'package:in_sreerajp_imgvidgal/widgets/made_with_love.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:in_sreerajp_imgvidgal/core/l10n/sanskrit_fallback_delegates.dart';
import '../../helpers/locale_checks.dart';

void main() {
  Future<void> pumpAbout(
    WidgetTester tester,
    AppConfig config, {
    Locale locale = const Locale('en'),
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          appConfigProvider.overrideWith((ref) async => config),
        ],
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AboutScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  const plainName = LocalizedText.plain('Gallery');
  const plainDescription = LocalizedText.plain('Local media.');

  group('AboutScreen fixed rows', () {
    testWidgets(
      'shows the app name, description, version, build, and build date',
      (tester) async {
        await pumpAbout(
          tester,
          const AppConfig(
            appName: LocalizedText.plain('Test Gallery'),
            description: LocalizedText.plain('A gallery for testing.'),
            version: '2.1.0',
            build: '17',
          ),
        );

        expect(find.text('Test Gallery'), findsOneWidget);
        expect(find.text('A gallery for testing.'), findsOneWidget);
        expect(find.text('2.1.0 — Build 17'), findsOneWidget);
        expect(find.text('Build date'), findsOneWidget);
        expect(find.text(kBuildDate), findsOneWidget);
      },
    );

    testWidgets('name and description follow the app language', (tester) async {
      await pumpAbout(
        tester,
        const AppConfig(
          appName: LocalizedText.byLocale(<String, String>{
            'en': 'Gallery',
            'ml': 'ഗാലറി',
          }),
          description: LocalizedText.byLocale(<String, String>{
            'en': 'Local media.',
            'ml': 'ഫോണിലെ ചിത്രങ്ങൾ.',
          }),
          version: '1.0.0',
          build: '1',
        ),
        locale: const Locale('ml'),
      );

      expect(find.text('ഗാലറി'), findsOneWidget);
      expect(find.text('ഫോണിലെ ചിത്രങ്ങൾ.'), findsOneWidget);
      expect(find.text('Gallery'), findsNothing);
    });
  });

  group('AboutScreen details', () {
    testWidgets('renders one row per entry, in order, with ARB labels', (
      tester,
    ) async {
      await pumpAbout(
        tester,
        const AppConfig(
          appName: plainName,
          description: plainDescription,
          version: '1.0.0',
          build: '1',
          details: <String, LocalizedText>{
            'author': LocalizedText.plain('Sreeraj P'),
            'license': LocalizedText.plain(
              'All libraries used are open source.',
            ),
            'security': LocalizedText.plain('AES-256-GCM'),
          },
        ),
      );

      expect(find.text('Author'), findsOneWidget);
      expect(find.text('Sreeraj P'), findsOneWidget);
      expect(find.text('License'), findsOneWidget);
      expect(find.text('Security'), findsOneWidget);
      expect(find.text('AES-256-GCM'), findsOneWidget);

      final authorY = tester.getTopLeft(find.text('Author')).dy;
      final securityY = tester.getTopLeft(find.text('Security')).dy;
      expect(authorY, lessThan(securityY));
    });

    testWidgets('labels are translated too', (tester) async {
      await pumpAbout(
        tester,
        const AppConfig(
          appName: plainName,
          description: plainDescription,
          version: '1.0.0',
          build: '1',
          details: <String, LocalizedText>{
            'author': LocalizedText.byLocale(<String, String>{
              'en': 'Sreeraj P',
              'ml': 'ശ്രീരാജ് പി',
            }),
          },
        ),
        locale: const Locale('ml'),
      );

      expect(find.text('രചയിതാവ്'), findsOneWidget);
      expect(find.text('ശ്രീരാജ് പി'), findsOneWidget);
      expect(find.text('Author'), findsNothing);
    });

    testWidgets('a key the screen has never heard of still appears', (
      tester,
    ) async {
      // The whole point of the config-driven rule: adding a row to the JSON
      // is the only change needed to make it show up here.
      await pumpAbout(
        tester,
        const AppConfig(
          appName: plainName,
          description: plainDescription,
          version: '1.0.0',
          build: '1',
          details: <String, LocalizedText>{
            'anythingAtAll': LocalizedText.plain('and its value'),
          },
        ),
      );

      expect(find.text('anythingAtAll'), findsOneWidget);
      expect(find.text('and its value'), findsOneWidget);
    });

    testWidgets('an entry with an empty key or value is skipped', (
      tester,
    ) async {
      await pumpAbout(
        tester,
        const AppConfig(
          appName: plainName,
          description: plainDescription,
          version: '1.0.0',
          build: '1',
          details: <String, LocalizedText>{
            'author': LocalizedText.plain('Sreeraj P'),
            '   ': LocalizedText.plain('orphan value'),
            'empty': LocalizedText.plain('   '),
          },
        ),
      );

      expect(find.text('Author'), findsOneWidget);
      expect(find.text('orphan value'), findsNothing);
      expect(find.text('empty'), findsNothing);
    });

    testWidgets('an email row is tappable and marked', (tester) async {
      await pumpAbout(
        tester,
        const AppConfig(
          appName: plainName,
          description: plainDescription,
          version: '1.0.0',
          build: '1',
          details: <String, LocalizedText>{
            'email': LocalizedText.plain('someone@example.com'),
            'author': LocalizedText.plain('Sreeraj P'),
          },
        ),
      );

      final emailTile = tester.widget<ListTile>(
        find.ancestor(
          of: find.text('someone@example.com'),
          matching: find.byType(ListTile),
        ),
      );
      expect(emailTile.onTap, isNotNull);
      expect(emailTile.trailing, isA<Icon>());

      // A plain row is not tappable.
      final authorTile = tester.widget<ListTile>(
        find.ancestor(of: find.text('Author'), matching: find.byType(ListTile)),
      );
      expect(authorTile.onTap, isNull);
    });

    testWidgets('a privacy-policy link is labelled, tappable and marked', (
      tester,
    ) async {
      await pumpAbout(
        tester,
        const AppConfig(
          appName: plainName,
          description: plainDescription,
          version: '1.0.0',
          build: '1',
          details: <String, LocalizedText>{
            'privacyPolicy': LocalizedText.plain('https://example.org/privacy'),
            'website': LocalizedText.plain('http://example.org'),
          },
        ),
      );

      expect(find.text('Privacy policy'), findsOneWidget);
      final link = tester.widget<ListTile>(
        find.ancestor(
          of: find.text('https://example.org/privacy'),
          matching: find.byType(ListTile),
        ),
      );
      expect(link.onTap, isNotNull);
      expect(link.trailing, isA<Icon>());

      // Only https opens; a plain http value is shown but not tappable.
      final plain = tester.widget<ListTile>(
        find.ancestor(
          of: find.text('http://example.org'),
          matching: find.byType(ListTile),
        ),
      );
      expect(plain.onTap, isNull);
    });

    testWidgets('the email key is matched whatever case it is written in', (
      tester,
    ) async {
      await pumpAbout(
        tester,
        const AppConfig(
          appName: plainName,
          description: plainDescription,
          version: '1.0.0',
          build: '1',
          details: <String, LocalizedText>{
            'eMaIl': LocalizedText.plain('someone@example.com'),
          },
        ),
      );

      final tile = tester.widget<ListTile>(
        find.ancestor(
          of: find.text('someone@example.com'),
          matching: find.byType(ListTile),
        ),
      );
      expect(tile.onTap, isNotNull);
    });

    testWidgets('no details means just the three fixed rows', (tester) async {
      await pumpAbout(
        tester,
        const AppConfig(
          appName: plainName,
          description: plainDescription,
          version: '1.0.0',
          build: '1',
        ),
      );

      expect(find.byType(ListTile), findsNWidgets(3));
    });
  });

  group('AboutScreen badge', () {
    testWidgets('ends with the Made with love badge', (tester) async {
      await pumpAbout(
        tester,
        const AppConfig(
          appName: plainName,
          description: plainDescription,
          version: '1.0.0',
          build: '1',
          details: <String, LocalizedText>{
            'author': LocalizedText.plain('Sreeraj P'),
          },
        ),
      );

      expect(find.byType(MadeWithLove), findsOneWidget);
      expect(
        find.bySemanticsLabel('Made with love from India'),
        findsOneWidget,
      );

      final badgeY = tester.getTopLeft(find.byType(MadeWithLove)).dy;
      final authorY = tester.getTopLeft(find.text('Author')).dy;
      expect(badgeY, greaterThan(authorY));
    });

    testWidgets('the badge follows the app language', (tester) async {
      await pumpAbout(tester, AppConfig.fallback, locale: const Locale('ml'));

      expect(
        find.bySemanticsLabel('സ്നേഹത്തോടെ ഇന്ത്യയിൽ നിന്ന്'),
        findsOneWidget,
      );
    });
  });

  group('AboutScreen fallback', () {
    testWidgets('the built-in config still renders', (tester) async {
      await pumpAbout(tester, AppConfig.fallback);

      expect(
        find.text(AppConfig.fallback.appName.resolve('en')),
        findsOneWidget,
      );
      expect(find.text('License'), findsOneWidget);
    });
  });

  group('every declared language', () {
    for (final locale in declaredLocales) {
      testWidgets('AboutScreen renders cleanly in ${locale.languageCode}', (
        tester,
      ) async {
        await pumpAbout(tester, AppConfig.fallback, locale: locale);
        expectLocaleClean(tester, locale);
      });
    }
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/config/app_config.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/build_date.g.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/providers/settings_providers.dart';
import 'package:in_sreerajp_imgvidgal/screens/settings/about_screen.dart';

void main() {
  Future<void> pumpAbout(WidgetTester tester, AppConfig config) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          appConfigProvider.overrideWith((ref) async => config),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AboutScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('AboutScreen fixed rows', () {
    testWidgets(
      'shows the app name, description, version, build, and build date',
      (tester) async {
        await pumpAbout(
          tester,
          const AppConfig(
            appName: 'Test Gallery',
            description: 'A gallery for testing.',
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
  });

  group('AboutScreen details', () {
    testWidgets('renders one row per entry, in order', (tester) async {
      await pumpAbout(
        tester,
        const AppConfig(
          appName: 'Gallery',
          description: 'Local media.',
          version: '1.0.0',
          build: '1',
          details: <String, String>{
            'Author': 'Sreeraj P',
            'License': 'All libraries used are open source.',
            'Security': 'AES-256-GCM',
          },
        ),
      );

      expect(find.text('Author'), findsOneWidget);
      expect(find.text('Sreeraj P'), findsOneWidget);
      expect(find.text('License'), findsOneWidget);
      expect(find.text('Security'), findsOneWidget);
      expect(find.text('AES-256-GCM'), findsOneWidget);
    });

    testWidgets('a key the screen has never heard of still appears', (
      tester,
    ) async {
      // The whole point of the config-driven rule: adding a row to the JSON
      // is the only change needed to make it show up here.
      await pumpAbout(
        tester,
        const AppConfig(
          appName: 'Gallery',
          description: 'Local media.',
          version: '1.0.0',
          build: '1',
          details: <String, String>{'Anything At All': 'and its value'},
        ),
      );

      expect(find.text('Anything At All'), findsOneWidget);
      expect(find.text('and its value'), findsOneWidget);
    });

    testWidgets('an entry with an empty key or value is skipped', (
      tester,
    ) async {
      await pumpAbout(
        tester,
        const AppConfig(
          appName: 'Gallery',
          description: 'Local media.',
          version: '1.0.0',
          build: '1',
          details: <String, String>{
            'Author': 'Sreeraj P',
            '   ': 'orphan value',
            'Empty': '   ',
          },
        ),
      );

      expect(find.text('Author'), findsOneWidget);
      expect(find.text('orphan value'), findsNothing);
      expect(find.text('Empty'), findsNothing);
    });

    testWidgets('an email row is tappable and marked', (tester) async {
      await pumpAbout(
        tester,
        const AppConfig(
          appName: 'Gallery',
          description: 'Local media.',
          version: '1.0.0',
          build: '1',
          details: <String, String>{
            'Email': 'someone@example.com',
            'Author': 'Sreeraj P',
          },
        ),
      );

      final emailTile = tester.widget<ListTile>(
        find.ancestor(of: find.text('Email'), matching: find.byType(ListTile)),
      );
      expect(emailTile.onTap, isNotNull);
      expect(emailTile.trailing, isA<Icon>());

      // A plain row is not tappable.
      final authorTile = tester.widget<ListTile>(
        find.ancestor(of: find.text('Author'), matching: find.byType(ListTile)),
      );
      expect(authorTile.onTap, isNull);
    });

    testWidgets('the key is matched whatever case it is written in', (
      tester,
    ) async {
      await pumpAbout(
        tester,
        const AppConfig(
          appName: 'Gallery',
          description: 'Local media.',
          version: '1.0.0',
          build: '1',
          details: <String, String>{'eMaIl': 'someone@example.com'},
        ),
      );

      final tile = tester.widget<ListTile>(
        find.ancestor(of: find.text('eMaIl'), matching: find.byType(ListTile)),
      );
      expect(tile.onTap, isNotNull);
    });

    testWidgets('no details means just the three fixed rows', (tester) async {
      await pumpAbout(
        tester,
        const AppConfig(
          appName: 'Gallery',
          description: 'Local media.',
          version: '1.0.0',
          build: '1',
        ),
      );

      expect(find.byType(ListTile), findsNWidgets(3));
    });
  });

  group('AboutScreen fallback', () {
    testWidgets('the built-in config still renders', (tester) async {
      await pumpAbout(tester, AppConfig.fallback);

      expect(find.text(AppConfig.fallback.appName), findsOneWidget);
      expect(find.text('License'), findsOneWidget);
    });
  });
}

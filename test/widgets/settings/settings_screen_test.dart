import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/settings/app_settings.dart';
import 'package:in_sreerajp_imgvidgal/providers/settings_providers.dart';
import 'package:in_sreerajp_imgvidgal/screens/settings/appearance_settings_screen.dart';
import 'package:in_sreerajp_imgvidgal/screens/settings/default_app_settings_screen.dart';
import 'package:in_sreerajp_imgvidgal/screens/settings/help_settings_screen.dart';
import 'package:in_sreerajp_imgvidgal/screens/settings/language_settings_screen.dart';
import 'package:in_sreerajp_imgvidgal/screens/settings/privacy_settings_screen.dart';
import 'package:in_sreerajp_imgvidgal/screens/settings/safety_settings_screen.dart';
import 'package:in_sreerajp_imgvidgal/screens/settings/settings_screen.dart';
import 'package:in_sreerajp_imgvidgal/services/settings/app_settings_service.dart';
import 'package:in_sreerajp_imgvidgal/theme/app_theme.dart';

import '../../helpers/recording_settings_service.dart';

void main() {
  late RecordingSettingsService service;

  setUp(() => service = RecordingSettingsService());

  Future<ProviderContainer> pumpTestWidget(
    WidgetTester tester, {
    required Widget child,
    AppSettings initial = AppSettings.defaults,
    Locale locale = const Locale('en'),
  }) async {
    tester.view.physicalSize = const Size(1200, 3600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: <Override>[
        appSettingsServiceProvider.overrideWith((ref) async => service),
        appSettingsProvider.overrideWith(
          (ref) => AppSettingsNotifier(
            service: () async => service,
            initial: initial,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: child,
        ),
      ),
    );
    await tester.pumpAndSettle();

    return container;
  }

  group('SettingsScreen hub rendering', () {
    testWidgets('shows every category card on hub', (tester) async {
      await pumpTestWidget(tester, child: const SettingsScreen());

      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Safety'), findsOneWidget);
      expect(find.text('Default Gallery App'), findsOneWidget);
      expect(find.text('Storage and privacy'), findsOneWidget);
      expect(find.text('Help & Guides'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
      expect(find.text('Reset settings'), findsOneWidget);
    });

    testWidgets('shows settings sections inside Cards', (tester) async {
      await pumpTestWidget(tester, child: const SettingsScreen());

      // Production flavor renders 8 cards:
      // Appearance, Language, Safety, Default App, Privacy, Help, About, Reset.
      expect(find.byType(Card), findsNWidgets(8));
    });

    testWidgets('renders in Malayalam when that is the locale', (tester) async {
      await pumpTestWidget(
        tester,
        child: const SettingsScreen(),
        locale: const Locale('ml'),
      );

      // The card titles follow the locale.
      expect(find.text('ഭാഷ'), findsOneWidget);
      expect(find.text('Appearance'), findsNothing);
    });

    testWidgets('hides the developer panel on a production build', (
      tester,
    ) async {
      await pumpTestWidget(tester, child: const SettingsScreen());

      expect(find.text('Developer'), findsNothing);
    });
  });

  group('SettingsScreen reset', () {
    testWidgets('asks first, and cancelling changes nothing', (tester) async {
      final container = await pumpTestWidget(
        tester,
        child: const SettingsScreen(),
        initial: const AppSettings(
          theme: ThemePreference.amoled,
          localeCode: 'ml',
        ),
      );

      await tester.tap(find.text('Reset settings'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(container.read(appSettingsProvider).theme, ThemePreference.amoled);
      expect(container.read(appSettingsProvider).localeCode, 'ml');
    });

    testWidgets('confirming puts everything back', (tester) async {
      final container = await pumpTestWidget(
        tester,
        child: const SettingsScreen(),
        initial: const AppSettings(
          theme: ThemePreference.amoled,
          localeCode: 'ml',
          gridColumns: 5,
          showFlashbacks: false,
        ),
      );

      await tester.tap(find.text('Reset settings'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      expect(container.read(appSettingsProvider), AppSettings.defaults);
      expect(find.text('Settings put back to the defaults.'), findsOneWidget);
    });
  });

  group('AppearanceSettingsScreen', () {
    testWidgets('shows theme options, grid density, and flashbacks', (
      tester,
    ) async {
      await pumpTestWidget(
        tester,
        child: const AppearanceSettingsScreen(),
        initial: const AppSettings(gridColumns: 4),
      );

      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('Grid density'), findsOneWidget);
      expect(find.text('4 per row'), findsWidgets);
      expect(find.text('Show memories'), findsOneWidget);
    });

    testWidgets('picking a theme stores it', (tester) async {
      final container = await pumpTestWidget(
        tester,
        child: const AppearanceSettingsScreen(),
      );

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(container.read(appSettingsProvider).theme, ThemePreference.dark);
      expect(service.saved.last.theme, ThemePreference.dark);
    });

    testWidgets('turning memories off stores it', (tester) async {
      final container = await pumpTestWidget(
        tester,
        child: const AppearanceSettingsScreen(),
      );

      await tester.tap(find.text('Show memories'));
      await tester.pumpAndSettle();

      expect(container.read(appSettingsProvider).showFlashbacks, isFalse);
    });
  });

  group('LanguageSettingsScreen', () {
    testWidgets('shows the three language choices', (tester) async {
      await pumpTestWidget(tester, child: const LanguageSettingsScreen());

      expect(find.text('System default'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('മലയാളം'), findsOneWidget);
    });

    testWidgets('picking a language stores it', (tester) async {
      final container = await pumpTestWidget(
        tester,
        child: const LanguageSettingsScreen(),
      );

      await tester.tap(find.text('മലയാളം'));
      await tester.pumpAndSettle();

      expect(container.read(appSettingsProvider).localeCode, 'ml');
    });

    testWidgets('going back to the system language clears the choice', (
      tester,
    ) async {
      final container = await pumpTestWidget(
        tester,
        child: const LanguageSettingsScreen(),
        initial: const AppSettings(localeCode: 'ml'),
        locale: const Locale('ml'),
      );

      await tester.tap(find.text('സിസ്റ്റം ഭാഷ'));
      await tester.pumpAndSettle();

      expect(container.read(appSettingsProvider).localeCode, isNull);
    });
  });

  group('SafetySettingsScreen', () {
    testWidgets('turning the delete confirmation off stores it', (
      tester,
    ) async {
      final container = await pumpTestWidget(
        tester,
        child: const SafetySettingsScreen(),
      );

      await tester.tap(find.text('Ask before deleting'));
      await tester.pumpAndSettle();

      expect(container.read(appSettingsProvider).confirmDestructive, isFalse);
    });
  });

  group('DefaultAppSettingsScreen', () {
    testWidgets('shows instructions and button to open settings', (
      tester,
    ) async {
      await pumpTestWidget(tester, child: const DefaultAppSettingsScreen());

      expect(find.text('Open Android Settings'), findsOneWidget);
    });
  });

  group('PrivacySettingsScreen', () {
    testWidgets('states plainly that there is no remote server', (
      tester,
    ) async {
      await pumpTestWidget(tester, child: const PrivacySettingsScreen());

      expect(find.text('No remote server'), findsOneWidget);
      expect(find.text('Vault settings'), findsOneWidget);
      expect(find.text('Backup and restore'), findsOneWidget);
    });
  });

  group('HelpSettingsScreen', () {
    testWidgets('shows help topic cards', (tester) async {
      await pumpTestWidget(tester, child: const HelpSettingsScreen());

      expect(find.text('Timeline & Memories'), findsOneWidget);
      expect(find.text('Secure Private Vault'), findsOneWidget);
      expect(find.text('Local Wi-Fi Transfer'), findsOneWidget);
      expect(find.text('Duplicate Cleaner'), findsOneWidget);
    });
  });

  group('AppSettingsService type', () {
    test('the recording store stands in for the real one', () {
      expect(service, isA<AppSettingsService>());
    });
  });
}

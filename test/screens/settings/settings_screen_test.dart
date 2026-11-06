import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/settings/app_settings.dart';
import 'package:in_sreerajp_imgvidgal/providers/settings_providers.dart';
import 'package:in_sreerajp_imgvidgal/screens/settings/appearance_settings_screen.dart';
import 'package:in_sreerajp_imgvidgal/screens/settings/default_app_settings_screen.dart';
import 'package:in_sreerajp_imgvidgal/screens/settings/help_settings_screen.dart';
import 'package:in_sreerajp_imgvidgal/screens/settings/language_settings_screen.dart';
import 'package:in_sreerajp_imgvidgal/screens/settings/permissions_settings_screen.dart';
import 'package:in_sreerajp_imgvidgal/models/media/media_permission_status.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/screens/settings/privacy_settings_screen.dart';
import 'package:in_sreerajp_imgvidgal/screens/settings/safety_settings_screen.dart';
import 'package:in_sreerajp_imgvidgal/screens/settings/settings_screen.dart';
import 'package:in_sreerajp_imgvidgal/services/settings/app_settings_service.dart';
import 'package:in_sreerajp_imgvidgal/theme/app_theme.dart';

import '../../helpers/recording_settings_service.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:in_sreerajp_imgvidgal/core/l10n/sanskrit_fallback_delegates.dart';
import '../../helpers/locale_checks.dart';

void main() {
  late RecordingSettingsService service;

  setUp(() => service = RecordingSettingsService());

  Future<ProviderContainer> pumpTestWidget(
    WidgetTester tester, {
    required Widget child,
    AppSettings initial = AppSettings.defaults,
    Locale locale = const Locale('en'),
    List<Override> extraOverrides = const <Override>[],
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
        ...extraOverrides,
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: appLocalizationsDelegates,
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
      expect(find.text('Privacy'), findsOneWidget);
      expect(find.text('Permissions'), findsOneWidget);
      expect(find.text('Backup and restore'), findsOneWidget);
      expect(find.text('Help & Guides'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
      expect(find.text('Reset settings'), findsOneWidget);
    });

    testWidgets('shows settings sections inside Cards', (tester) async {
      await pumpTestWidget(tester, child: const SettingsScreen());

      // Production flavor renders 10 cards: Appearance, Language, Safety,
      // Default App, Privacy, Permissions, Backup, Help, About, Reset.
      expect(find.byType(Card), findsNWidgets(10));
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

      await tester.tap(find.text('സിസ്റ്റം സ്വതവേ'));
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
    testWidgets('shows instructions and no settings button', (tester) async {
      await pumpTestWidget(tester, child: const DefaultAppSettingsScreen());

      expect(find.text('Set Default Gallery'), findsOneWidget);
      expect(find.textContaining('Open by default'), findsOneWidget);
      // Android has no "default gallery" settings page, so no button.
      expect(find.text('Open Android Settings'), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
    });
  });

  group('PrivacySettingsScreen', () {
    testWidgets('holds only hide content and vault settings', (tester) async {
      await pumpTestWidget(tester, child: const PrivacySettingsScreen());

      expect(find.text('Privacy'), findsOneWidget);
      expect(find.text('Hide content'), findsOneWidget);
      expect(find.text('Vault settings'), findsOneWidget);
      expect(find.text('No remote server'), findsNothing);
      expect(find.text('Backup and restore'), findsNothing);
    });
  });

  group('PermissionsSettingsScreen', () {
    Future<void> pumpPermissions(
      WidgetTester tester, {
      MediaPermissionStatus status = MediaPermissionStatus.granted,
      Locale locale = const Locale('en'),
    }) async {
      await pumpTestWidget(
        tester,
        child: const PermissionsSettingsScreen(),
        locale: locale,
        extraOverrides: <Override>[
          mediaPermissionStatusProvider.overrideWith((ref) async => status),
        ],
      );
    }

    testWidgets('keeps the Open settings button above the navigation bar', (
      tester,
    ) async {
      await pumpPermissions(tester);

      // A phone-sized screen with a 48 px system navigation bar, so the list
      // has to scroll and its end meets the bar.
      tester.view.physicalSize = const Size(400, 800);
      tester.view.padding = const FakeViewPadding(bottom: 48);
      tester.view.viewPadding = const FakeViewPadding(bottom: 48);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -20000));
      await tester.pumpAndSettle();

      final button = tester.getRect(find.text('Open settings'));
      expect(button.bottom, lessThanOrEqualTo(800 - 48));
    });

    testWidgets('lists all three groups and every row', (tester) async {
      await pumpPermissions(tester);

      expect(find.text('No remote server'), findsOneWidget);
      expect(find.text('You allow these'), findsOneWidget);
      expect(find.text('Granted at install'), findsOneWidget);
      expect(find.text('Removed on purpose'), findsOneWidget);
      expect(find.text('Photos and videos'), findsOneWidget);
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Local network'), findsOneWidget);
      expect(find.text('Keep phone awake'), findsOneWidget);
      expect(find.text('Open settings'), findsOneWidget);
    });

    testWidgets('shows the Android names with version notes', (tester) async {
      await pumpPermissions(tester);

      expect(find.textContaining('INTERNET'), findsOneWidget);
      expect(
        find.textContaining('READ_EXTERNAL_STORAGE (Up to Android 12)'),
        findsOneWidget,
      );
      expect(
        find.textContaining('READ_MEDIA_VISUAL_USER_SELECTED (Android 14+)'),
        findsOneWidget,
      );
    });

    testWidgets('shows the live photos and videos state', (tester) async {
      await pumpPermissions(tester, status: MediaPermissionStatus.partial);
      expect(find.text('Selected only'), findsOneWidget);
    });

    testWidgets('says not allowed when media access is refused', (
      tester,
    ) async {
      await pumpPermissions(
        tester,
        status: MediaPermissionStatus.permanentlyDenied,
      );
      expect(find.text('Not allowed'), findsOneWidget);
    });

    for (final locale in declaredLocales) {
      testWidgets('renders cleanly in ${locale.languageCode}', (tester) async {
        await pumpPermissions(tester, locale: locale);
        expectLocaleClean(tester, locale);
      });
    }
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

  group('every declared language', () {
    for (final locale in declaredLocales) {
      testWidgets('SettingsScreen renders cleanly in ${locale.languageCode}', (
        tester,
      ) async {
        await pumpTestWidget(
          tester,
          child: const SettingsScreen(),
          locale: locale,
        );
        expectLocaleClean(tester, locale);
      });
    }
  });
}

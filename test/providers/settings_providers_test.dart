import 'dart:io';

import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/settings/app_settings.dart';
import 'package:in_sreerajp_imgvidgal/providers/settings_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/theme_provider.dart';
import 'package:in_sreerajp_imgvidgal/services/settings/app_settings_service.dart';
import 'package:in_sreerajp_imgvidgal/theme/app_theme.dart';

import '../helpers/recording_settings_service.dart';

void main() {
  late RecordingSettingsService service;

  /// A container whose settings notifier writes into [service].
  ProviderContainer containerWith({
    AppSettings initial = AppSettings.defaults,
  }) {
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
    return container;
  }

  setUp(() => service = RecordingSettingsService());

  group('AppSettingsNotifier', () {
    test('a theme change is kept and written through', () async {
      final container = containerWith();

      await container
          .read(appSettingsProvider.notifier)
          .setTheme(ThemePreference.amoled);

      expect(container.read(appSettingsProvider).theme, ThemePreference.amoled);
      expect(service.saved.single.theme, ThemePreference.amoled);
    });

    test('a language change is kept and written through', () async {
      final container = containerWith();

      await container.read(appSettingsProvider.notifier).setLocaleCode('ml');

      expect(container.read(appSettingsProvider).localeCode, 'ml');
      expect(service.saved.single.localeCode, 'ml');
    });

    test('passing null goes back to following the phone', () async {
      final container = containerWith(
        initial: const AppSettings(localeCode: 'ml'),
      );

      await container.read(appSettingsProvider.notifier).setLocaleCode(null);

      expect(container.read(appSettingsProvider).localeCode, isNull);
      expect(service.saved.single.localeCode, isNull);
    });

    test('a column count outside the range is clamped before saving', () async {
      final container = containerWith();

      await container.read(appSettingsProvider.notifier).setGridColumns(99);

      expect(container.read(appSettingsProvider).gridColumns, 5);
      expect(service.saved.single.gridColumns, 5);
    });

    test('setting the value it already has writes nothing', () async {
      final container = containerWith(
        initial: const AppSettings(theme: ThemePreference.dark),
      );

      await container
          .read(appSettingsProvider.notifier)
          .setTheme(ThemePreference.dark);

      expect(service.saved, isEmpty);
    });

    test('the reset puts everything back and saves that', () async {
      final container = containerWith(
        initial: const AppSettings(
          theme: ThemePreference.amoled,
          localeCode: 'ml',
          gridColumns: 5,
          showFlashbacks: false,
          confirmDestructive: false,
        ),
      );

      await container.read(appSettingsProvider.notifier).resetToDefaults();

      expect(container.read(appSettingsProvider), AppSettings.defaults);
      expect(service.saved.single, AppSettings.defaults);
    });

    test('a failed save leaves the chosen value on screen', () async {
      // The screen the user is looking at is already right. Losing the write
      // costs them the value on the next launch, and nothing sooner; it is
      // not worth an error.
      final container = containerWith();
      service.failNextSave = true;

      await container
          .read(appSettingsProvider.notifier)
          .setTheme(ThemePreference.light);

      expect(container.read(appSettingsProvider).theme, ThemePreference.light);
    });

    test('a store that throws does not take the change down with it', () async {
      final container = ProviderContainer(
        overrides: <Override>[
          appSettingsProvider.overrideWith(
            (ref) => AppSettingsNotifier(
              service: () async => throw const FileSystemException('no disk'),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(appSettingsProvider.notifier)
          .setTheme(ThemePreference.dark);

      expect(container.read(appSettingsProvider).theme, ThemePreference.dark);
    });
  });

  group('derived providers', () {
    test('the theme provider follows the stored theme', () async {
      final container = containerWith();

      expect(container.read(themeProvider), ThemePreference.system);

      await container
          .read(appSettingsProvider.notifier)
          .setTheme(ThemePreference.light);

      expect(container.read(themeProvider), ThemePreference.light);
    });

    test('no language choice means no locale, so the phone decides', () {
      final container = containerWith();

      expect(container.read(localeProvider), isNull);
    });

    test('a language choice becomes that locale', () async {
      final container = containerWith();

      await container.read(appSettingsProvider.notifier).setLocaleCode('ml');

      expect(container.read(localeProvider), const Locale('ml'));
    });

    test('the two switches are exposed on their own', () async {
      final container = containerWith();

      expect(container.read(confirmDestructiveProvider), isTrue);
      expect(container.read(showFlashbacksProvider), isTrue);

      final notifier = container.read(appSettingsProvider.notifier);
      await notifier.setConfirmDestructive(false);
      await notifier.setShowFlashbacks(false);

      expect(container.read(confirmDestructiveProvider), isFalse);
      expect(container.read(showFlashbacksProvider), isFalse);
    });
  });

  group('the recording store', () {
    test('stands in for the real service', () {
      expect(service, isA<AppSettingsService>());
    });
  });
}

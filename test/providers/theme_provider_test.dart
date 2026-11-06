import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/settings/app_settings.dart';
import 'package:in_sreerajp_imgvidgal/providers/settings_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/theme_provider.dart';
import 'package:in_sreerajp_imgvidgal/theme/app_theme.dart';

import '../helpers/recording_settings_service.dart';

void main() {
  test('follows the theme in the settings', () async {
    final service = RecordingSettingsService();
    final container = ProviderContainer(
      overrides: <Override>[
        appSettingsProvider.overrideWith(
          (ref) => AppSettingsNotifier(
            service: () async => service,
            initial: const AppSettings(theme: ThemePreference.dark),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(themeProvider), ThemePreference.dark);

    await container
        .read(appSettingsProvider.notifier)
        .setTheme(ThemePreference.light);

    expect(container.read(themeProvider), ThemePreference.light);
    expect(service.saved.last.theme, ThemePreference.light);
  });
}

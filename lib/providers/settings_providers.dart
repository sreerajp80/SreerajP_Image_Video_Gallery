import 'dart:ui' show Locale;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/core/config/app_config.dart';
import 'package:in_sreerajp_imgvidgal/core/config/config_service.dart';
import 'package:in_sreerajp_imgvidgal/models/settings/app_settings.dart';
import 'package:in_sreerajp_imgvidgal/services/settings/app_settings_service.dart';
import 'package:in_sreerajp_imgvidgal/theme/app_theme.dart';
import 'package:path_provider/path_provider.dart';

/// Where the preferences file lives, once the app support directory is known.
final appSettingsServiceProvider = FutureProvider<AppSettingsService>((
  ref,
) async {
  final directory = await getApplicationSupportDirectory();
  return AppSettingsService(directory: directory);
});

/// Holds the current preferences and writes every change back to disk.
///
/// The state changes first and the save follows. A save that fails is not
/// reported: the screen the user is looking at is already correct, and the
/// only cost is that the next launch starts from the older value. That is a
/// far better outcome than an error dialog over a theme switch.
class AppSettingsNotifier extends StateNotifier<AppSettings> {
  final Future<AppSettingsService> Function() _service;

  AppSettingsNotifier({
    required Future<AppSettingsService> Function() service,
    AppSettings initial = AppSettings.defaults,
  }) : _service = service,
       super(initial);

  Future<void> setTheme(ThemePreference theme) =>
      _update(state.copyWith(theme: theme));

  /// Sets the language, or passes `null` to follow the phone again.
  Future<void> setLocaleCode(String? code) => _update(
    code == null
        ? state.copyWith(clearLocaleCode: true)
        : state.copyWith(localeCode: code),
  );

  Future<void> setGridColumns(int columns) =>
      _update(state.copyWith(gridColumns: columns));

  Future<void> setShowFlashbacks(bool value) =>
      _update(state.copyWith(showFlashbacks: value));

  Future<void> setConfirmDestructive(bool value) =>
      _update(state.copyWith(confirmDestructive: value));

  /// Puts everything back to how a fresh install starts.
  Future<void> resetToDefaults() => _update(AppSettings.defaults);

  Future<void> _update(AppSettings updated) async {
    if (updated == state) return;
    state = updated;
    try {
      final service = await _service();
      await service.save(updated);
    } catch (_) {
      // Nothing to do and nothing worth saying. See the class comment.
    }
  }
}

/// The user's preferences.
///
/// `main()` seeds this with what was on disk before the first frame is built,
/// through a [ProviderScope] override, so the app never flashes the wrong
/// theme or the wrong language on launch.
final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
      return AppSettingsNotifier(
        service: () => ref.read(appSettingsServiceProvider.future),
      );
    });

/// The locale to run in, or `null` to follow the phone.
final localeProvider = Provider<Locale?>((ref) {
  final code = ref.watch(appSettingsProvider.select((s) => s.localeCode));
  return code == null ? null : Locale(code);
});

/// Whether the app asks again before anything it cannot undo.
final confirmDestructiveProvider = Provider<bool>((ref) {
  return ref.watch(appSettingsProvider.select((s) => s.confirmDestructive));
});

/// Whether the timeline shows its flashback memories row.
final showFlashbacksProvider = Provider<bool>((ref) {
  return ref.watch(appSettingsProvider.select((s) => s.showFlashbacks));
});

/// The About screen's metadata, read from `assets/config/app_config.json`.
///
/// `loadAndVerify` degrades to [AppConfig.fallback] rather than throwing, so
/// this never lands in an error state over a bad config file.
final appConfigProvider = FutureProvider<AppConfig>((ref) async {
  return ConfigService().loadAndVerify();
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/providers/settings_providers.dart';
import 'package:in_sreerajp_imgvidgal/theme/app_theme.dart';

/// The theme the app is painting in.
///
/// A read of the stored preferences rather than a store of its own, so a
/// theme change survives a restart. Set a new one through
/// `appSettingsProvider.notifier.setTheme(...)`, which saves as it goes.
final themeProvider = Provider<ThemePreference>((ref) {
  return ref.watch(appSettingsProvider.select((s) => s.theme));
});

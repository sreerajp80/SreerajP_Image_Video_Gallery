import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/settings/app_settings.dart';
import 'package:in_sreerajp_imgvidgal/providers/settings_providers.dart';
import 'package:in_sreerajp_imgvidgal/theme/app_theme.dart';

/// Screen for configuring theme, grid density, and flashback memories.
class AppearanceSettingsScreen extends ConsumerWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsAppearance)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: <Widget>[
          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _ThemeSection(settings: settings),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _GridDensitySection(settings: settings),
                const Divider(height: 1, indent: 16, endIndent: 16),
                SwitchListTile(
                  secondary: const Icon(Icons.auto_awesome_outlined),
                  title: Text(
                    l10n.showFlashbacks,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(l10n.showFlashbacksSubtitle),
                  value: settings.showFlashbacks,
                  onChanged: (value) => ref
                      .read(appSettingsProvider.notifier)
                      .setShowFlashbacks(value),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeSection extends ConsumerWidget {
  final AppSettings settings;

  const _ThemeSection({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.theme,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<ThemePreference>(
              showSelectedIcon: false,
              segments: <ButtonSegment<ThemePreference>>[
                ButtonSegment<ThemePreference>(
                  value: ThemePreference.system,
                  label: Text(l10n.themeSystem),
                  icon: const Icon(Icons.brightness_auto),
                ),
                ButtonSegment<ThemePreference>(
                  value: ThemePreference.light,
                  label: Text(l10n.themeLight),
                  icon: const Icon(Icons.light_mode),
                ),
                ButtonSegment<ThemePreference>(
                  value: ThemePreference.dark,
                  label: Text(l10n.themeDark),
                  icon: const Icon(Icons.dark_mode),
                ),
                ButtonSegment<ThemePreference>(
                  value: ThemePreference.amoled,
                  label: Text(l10n.themeAmoled),
                  icon: const Icon(Icons.contrast),
                ),
              ],
              selected: <ThemePreference>{settings.theme},
              onSelectionChanged: (selection) {
                ref
                    .read(appSettingsProvider.notifier)
                    .setTheme(selection.first);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GridDensitySection extends ConsumerWidget {
  final AppSettings settings;

  const _GridDensitySection({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                l10n.gridDensity,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                l10n.gridDensityValue(settings.gridColumns),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Slider(
            value: settings.gridColumns.toDouble(),
            min: AppConstants.minGridColumns.toDouble(),
            max: AppConstants.maxGridColumns.toDouble(),
            divisions:
                AppConstants.maxGridColumns - AppConstants.minGridColumns,
            label: l10n.gridDensityValue(settings.gridColumns),
            onChanged: (value) => ref
                .read(appSettingsProvider.notifier)
                .setGridColumns(value.round()),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              l10n.gridDensitySubtitle,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

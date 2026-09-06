import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/providers/settings_providers.dart';

/// Screen for safety and destructive action confirmation settings.
class SafetySettingsScreen extends ConsumerWidget {
  const SafetySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsSafety)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: <Widget>[
          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: SwitchListTile(
              secondary: const Icon(Icons.shield_outlined),
              title: Text(
                l10n.confirmDestructive,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(l10n.confirmDestructiveSubtitle),
              value: settings.confirmDestructive,
              onChanged: (value) => ref
                  .read(appSettingsProvider.notifier)
                  .setConfirmDestructive(value),
            ),
          ),
        ],
      ),
    );
  }
}

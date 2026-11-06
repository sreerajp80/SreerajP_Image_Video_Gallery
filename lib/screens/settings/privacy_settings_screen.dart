import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_sreerajp_imgvidgal/core/routing/app_router.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/providers/settings_providers.dart';

/// Screen for privacy settings: hiding screen content and the vault.
///
/// Backup and the permission list have their own cards on the settings hub.
class PrivacySettingsScreen extends ConsumerWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final protectAll = ref.watch(
      appSettingsProvider.select((s) => s.protectAllScreens),
    );
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    Widget iconBox(IconData icon) => Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: colorScheme.primary, size: 22),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.titleSettingsPrivacy)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: <Widget>[
            Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: <Widget>[
                  SwitchListTile(
                    secondary: iconBox(Icons.visibility_off_outlined),
                    title: Text(
                      l10n.titleSettingsProtectScreens,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(l10n.descSettingsProtectScreens),
                    isThreeLine: true,
                    value: protectAll,
                    onChanged: (value) => ref
                        .read(appSettingsProvider.notifier)
                        .setProtectAllScreens(value),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: iconBox(Icons.lock_outline),
                    title: Text(
                      l10n.titleVaultSettings,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(l10n.descVaultSettingsOpenSubtitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(kRouteVaultSettings),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

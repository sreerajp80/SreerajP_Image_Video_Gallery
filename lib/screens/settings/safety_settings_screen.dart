import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/settings_providers.dart';

/// Screen for safety and destructive action confirmation settings.
class SafetySettingsScreen extends ConsumerWidget {
  const SafetySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.titleSettingsSafety)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: <Widget>[
            Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: SwitchListTile(
                secondary: const Icon(Icons.shield_outlined),
                title: Text(
                  l10n.titleConfirmDestructive,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(l10n.descConfirmDestructiveSubtitle),
                value: settings.confirmDestructive,
                onChanged: (value) => ref
                    .read(appSettingsProvider.notifier)
                    .setConfirmDestructive(value),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: SwitchListTile(
                secondary: const Icon(Icons.delete_forever_outlined),
                title: Text(
                  l10n.titleSecureDelete,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(l10n.descSecureDeleteSubtitle),
                value: settings.secureDelete,
                onChanged: (value) => ref
                    .read(appSettingsProvider.notifier)
                    .setSecureDelete(value),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                l10n.bodySecureDeleteVaultNote,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const _ManageMediaCard(),
          ],
        ),
      ),
    );
  }
}

/// "Manage media" (Android 12+): shows whether it is on, and opens Android's
/// own page to change it. Android never prompts for it, so this card is the
/// way in. Hidden on older Android, where it does not exist.
///
/// The state is read again whenever the app comes back to the front, since
/// the user changes it in Android settings, outside the app.
class _ManageMediaCard extends ConsumerStatefulWidget {
  const _ManageMediaCard();

  @override
  ConsumerState<_ManageMediaCard> createState() => _ManageMediaCardState();
}

class _ManageMediaCardState extends ConsumerState<_ManageMediaCard> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.invalidate(deleteConfirmInfoProvider),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final info = ref.watch(deleteConfirmInfoProvider).value;
    if (info == null || !info.manageMediaSupported) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bool on = info.manageMediaGranted;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          key: const ValueKey<String>('manage_media_card'),
          leading: const Icon(Icons.perm_media_outlined),
          title: Text(
            l10n.labelPermManageMedia,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(l10n.descManageMediaSubtitle),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: on
                  ? scheme.primaryContainer
                  : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              on ? l10n.labelPermAllowed : l10n.labelPermNotAllowed,
              style: theme.textTheme.labelSmall?.copyWith(
                color: on ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
              ),
            ),
          ),
          onTap: () =>
              ref.read(mediaStoreChannelProvider).openManageMediaSettings(),
        ),
      ),
    );
  }
}

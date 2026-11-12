import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_sreerajp_imgvidgal/core/routing/app_router.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/sync_role.dart';
import 'package:in_sreerajp_imgvidgal/providers/sync_providers.dart';

/// Where a receive starts: this phone always receives.
///
/// Opened from the home menu and from Settings › Device Sync › "Get from
/// your old phone". Sending starts elsewhere: from a selection ("Send to
/// device") or from "Move to a new phone". Either phone may show the code, so
/// both choices are offered.
///
/// No socket is opened here. The listener belongs to the receive screen and
/// the connection to the scan screen, so this page can be left and returned
/// to without anything being left open behind it.
class SyncHomeScreen extends ConsumerWidget {
  const SyncHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final address = ref.watch(localNetworkAddressProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.titleSync)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(l10n.bodySyncIntro, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 16),
            const SyncPrivacyCard(),
            const SizedBox(height: 24),
            address.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) =>
                  SyncNoNetwork(message: l10n.bodySyncErrorNoNetwork),
              data: (found) {
                if (found == null) {
                  return SyncNoNetwork(message: l10n.bodySyncErrorNoNetwork);
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SyncChoiceCard(
                      icon: Icons.qr_code_2,
                      title: l10n.labelSyncShowCode,
                      body: l10n.bodySyncReceive,
                      onTap: () {
                        ref.read(syncRoleProvider.notifier).state =
                            SyncRole.receive;
                        context.push(kRouteSyncReceive);
                      },
                    ),
                    const SizedBox(height: 12),
                    SyncChoiceCard(
                      icon: Icons.qr_code_scanner,
                      title: l10n.labelSyncScanOther,
                      body: l10n.bodySyncScanSenderCode,
                      onTap: () {
                        // A typed code has no role in it; this phone
                        // receives, so the phone showing the code sends.
                        ref.read(syncRoleProvider.notifier).state =
                            SyncRole.receive;
                        context.push(kRouteSyncSend);
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.bodySyncHowToSend,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// The local-only promise, said on the screens that make it, not only in the
/// manifest comment where no user will ever read it.
class SyncPrivacyCard extends StatelessWidget {
  const SyncPrivacyCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.wifi_tethering,
              color: theme.colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.bodySyncPrivacyNote,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown when this device is not on a network it may transfer over.
class SyncNoNetwork extends StatelessWidget {
  final String message;

  const SyncNoNetwork({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(
            Icons.wifi_off_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

/// One of the choices on a transfer start screen.
class SyncChoiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;

  const SyncChoiceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(title),
        subtitle: Text(body),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

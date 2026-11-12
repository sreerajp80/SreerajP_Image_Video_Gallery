import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_sreerajp_imgvidgal/core/routing/app_router.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/transfer_purpose.dart';
import 'package:in_sreerajp_imgvidgal/providers/sync_providers.dart';

/// Settings › Device Sync: the one place to copy this app to another phone.
///
/// Two ways, each one-way and merge-only:
///
/// * **QR** carries the app's data alone (tags, albums, favourites, notes,
///   places). No network at all.
/// * **Wi-Fi** ("Move to a new phone") carries the folders and albums the
///   user picks, then the whole app data and settings on Finish, and the
///   private vault if the user turns it on. It uses the local transfer
///   screens.
///
/// Nothing is deleted on either phone by either way.
class DeviceSyncScreen extends ConsumerWidget {
  const DeviceSyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.titleDeviceSync)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(l10n.bodyDeviceSyncIntro, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 16),
            _SectionLabel(text: l10n.labelSyncSend),
            _SyncCard(
              icon: Icons.qr_code_2,
              title: l10n.labelDeviceSyncQrSend,
              body: l10n.bodyDeviceSyncQrSend,
              onTap: () => context.push(kRouteDeviceSyncQrSend),
            ),
            _SyncCard(
              icon: Icons.wifi,
              title: l10n.labelDeviceSyncWifiSend,
              body: l10n.bodyDeviceSyncWifiSend,
              onTap: () {
                ref.read(transferOutboxProvider.notifier).state =
                    const <MediaItem>[];
                ref.read(transferPurposeProvider.notifier).state =
                    TransferPurpose.phoneMove;
                context.push(kRouteSyncStartSend);
              },
            ),
            const SizedBox(height: 16),
            _SectionLabel(text: l10n.labelSyncReceive),
            _SyncCard(
              icon: Icons.qr_code_scanner,
              title: l10n.labelDeviceSyncQrReceive,
              body: l10n.bodyDeviceSyncQrReceive,
              onTap: () => context.push(kRouteDeviceSyncQrReceive),
            ),
            _SyncCard(
              icon: Icons.wifi_tethering,
              title: l10n.labelDeviceSyncWifiReceive,
              body: l10n.bodyDeviceSyncWifiReceive,
              // The receive start lets this phone show a code or scan one.
              onTap: () => context.push(kRouteSync),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _SyncCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;

  const _SyncCard({
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

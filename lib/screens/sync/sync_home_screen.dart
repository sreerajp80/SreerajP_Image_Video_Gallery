import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_sreerajp_imgvidgal/core/routing/app_router.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/sync_role.dart';
import 'package:in_sreerajp_imgvidgal/providers/sync_providers.dart';

/// Where a transfer starts: send or receive.
///
/// No socket is opened here. The listener belongs to the receive screen and
/// the connection to the send screen, so this page can be left and returned
/// to without anything being left open behind it.
class SyncHomeScreen extends ConsumerWidget {
  const SyncHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final address = ref.watch(localNetworkAddressProvider);
    final outbox = ref.watch(transferOutboxProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.syncTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(l10n.syncIntro, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 16),

            // The promise, said on the screen that makes it, not only in the
            // manifest comment where no user will ever read it.
            Card(
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
                        l10n.syncPrivacyNote,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            address.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => _NoNetwork(message: l10n.syncErrorNoNetwork),
              data: (found) {
                if (found == null) {
                  return _NoNetwork(message: l10n.syncErrorNoNetwork);
                }

                return Column(
                  children: [
                    _RoleCard(
                      icon: Icons.upload_outlined,
                      title: l10n.syncSend,
                      body: outbox.isEmpty
                          ? l10n.syncNothingSelected
                          : l10n.syncOfferHeading(outbox.length),
                      // Sending needs something to send. Offering the button
                      // with an empty outbox would only lead to a dead end.
                      onTap: outbox.isEmpty
                          ? null
                          : () {
                              ref.read(syncRoleProvider.notifier).state =
                                  SyncRole.send;
                              context.push(kRouteSyncReceive);
                            },
                    ),
                    const SizedBox(height: 12),
                    _RoleCard(
                      icon: Icons.download_outlined,
                      title: l10n.syncReceive,
                      body: l10n.syncReceiveBody,
                      onTap: () {
                        ref.read(syncRoleProvider.notifier).state =
                            SyncRole.receive;
                        context.push(kRouteSyncReceive);
                      },
                    ),
                    const SizedBox(height: 12),
                    _RoleCard(
                      icon: Icons.qr_code_scanner,
                      title: l10n.syncScanCode,
                      body: l10n.syncSendBody,
                      onTap: () => context.push(kRouteSyncSend),
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

/// Shown when this device is not on a network it may transfer over.
class _NoNetwork extends StatelessWidget {
  final String message;

  const _NoNetwork({required this.message});

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

/// One of the choices on this screen.
class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final VoidCallback? onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onTap != null;

    return Card(
      child: ListTile(
        enabled: enabled,
        leading: Icon(
          icon,
          color: enabled
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
        ),
        title: Text(title),
        subtitle: Text(body),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

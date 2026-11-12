import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_sreerajp_imgvidgal/core/routing/app_router.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/sync_role.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/transfer_purpose.dart';
import 'package:in_sreerajp_imgvidgal/models/vault/vault_lock_state.dart';
import 'package:in_sreerajp_imgvidgal/providers/sync_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/vault_providers.dart';
import 'package:in_sreerajp_imgvidgal/screens/sync/sync_home_screen.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Where a send starts: this phone always sends.
///
/// Opened two ways, told apart by [transferPurposeProvider]:
///
/// * a quick send of the photos the user selected ("Send to device");
/// * Settings › Device Sync › "Move to a new phone".
///
/// Either phone may show the pairing code, so both choices are offered. There
/// is no "Receive" here on purpose: the user came to send.
///
/// No socket is opened here. The listener belongs to the receive screen and
/// the connection to the scan screen.
class SendStartScreen extends ConsumerStatefulWidget {
  const SendStartScreen({super.key});

  @override
  ConsumerState<SendStartScreen> createState() => _SendStartScreenState();
}

class _SendStartScreenState extends ConsumerState<SendStartScreen> {
  /// Read once in `initState`: Riverpod 3 does not allow `ref` in `dispose`.
  late final StateController<List<MediaItem>> _outbox;
  late final StateController<bool> _includeVault;

  @override
  void initState() {
    super.initState();
    _outbox = ref.read(transferOutboxProvider.notifier);
    _includeVault = ref.read(phoneMoveIncludeVaultProvider.notifier);
    // The vault is never included unless chosen on this visit.
    Future.microtask(() => _includeVault.state = false);
  }

  @override
  void dispose() {
    // The photos picked for this send belong to this send only. Emptied on
    // the way out, so an old selection never shows up in a later transfer.
    // After the frame: providers must not change while the tree unmounts.
    final outbox = _outbox;
    final includeVault = _includeVault;
    Future.microtask(() {
      outbox.state = const <MediaItem>[];
      includeVault.state = false;
    });
    super.dispose();
  }

  /// Turns the vault on only after it has been unlocked on this phone.
  ///
  /// If it is locked, the vault's own gate opens; the user unlocks there and
  /// comes back. The switch turns on only if the vault is then open.
  Future<void> _setIncludeVault(bool on) async {
    if (!on) {
      _includeVault.state = false;
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final lock = ref.read(vaultLockControllerProvider.notifier);
    await lock.refreshStatus();
    if (!mounted) return;

    var status = ref.read(vaultLockControllerProvider).status;
    if (status == VaultLockStatus.notSetUp) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.bodySyncVaultNotSetUp)),
      );
      return;
    }
    if (status != VaultLockStatus.unlocked) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.bodySyncVaultUnlockFirst)),
      );
      await context.push(kRouteVault);
      if (!mounted) return;
      status = ref.read(vaultLockControllerProvider).status;
    }
    _includeVault.state = status == VaultLockStatus.unlocked;
  }

  void _showCode() {
    ref.read(syncRoleProvider.notifier).state = SyncRole.send;
    context.push(kRouteSyncReceive);
  }

  void _scanCode() {
    // A typed code has no role in it; this phone sends, so the phone showing
    // the code receives.
    ref.read(syncRoleProvider.notifier).state = SyncRole.send;
    context.push(kRouteSyncSend);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final purpose = ref.watch(transferPurposeProvider);
    final outbox = ref.watch(transferOutboxProvider);
    final address = ref.watch(localNetworkAddressProvider);
    final isMove = purpose == TransferPurpose.phoneMove;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isMove
              ? l10n.labelDeviceSyncWifiSend
              : l10n.titleSyncQuickSend(outbox.length),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              isMove ? l10n.bodySyncPhoneMoveIntro : l10n.bodySyncQuickIntro,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            const SyncPrivacyCard(),
            if (isMove) ...[
              const SizedBox(height: 16),
              Card(
                child: SwitchListTile(
                  secondary: Icon(
                    Icons.lock_outline,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(l10n.labelSyncIncludeVault),
                  subtitle: Text(
                    ref.watch(phoneMoveIncludeVaultProvider)
                        ? l10n.bodySyncIncludeVaultOn
                        : l10n.bodySyncIncludeVaultOff,
                  ),
                  value: ref.watch(phoneMoveIncludeVaultProvider),
                  onChanged: _setIncludeVault,
                ),
              ),
            ],
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
                  children: [
                    SyncChoiceCard(
                      icon: Icons.qr_code_2,
                      title: l10n.labelSyncShowCode,
                      body: l10n.bodySyncShowCodeToReceiver,
                      onTap: _showCode,
                    ),
                    const SizedBox(height: 12),
                    SyncChoiceCard(
                      icon: Icons.qr_code_scanner,
                      title: l10n.labelSyncScanOther,
                      body: l10n.bodySyncScanReceiverCode,
                      onTap: _scanCode,
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

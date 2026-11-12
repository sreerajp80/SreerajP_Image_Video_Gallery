import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/core/domain/sync/sync_selection_rules.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/sync_role.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/transfer_purpose.dart';
import 'package:in_sreerajp_imgvidgal/providers/album_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/selection_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/tag_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/vault_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/sync_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/viewer_providers.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/transfer_session_state.dart';
import 'package:in_sreerajp_imgvidgal/widgets/sync/pairing_qr_card.dart';
import 'package:in_sreerajp_imgvidgal/widgets/sync/transfer_session_body.dart';

// The failure text lives with the shared body now; re-exported so older
// imports of it from here keep working.
export 'package:in_sreerajp_imgvidgal/widgets/sync/transfer_session_body.dart'
    show failureMessage;

/// Shows the pairing code and waits for the other phone.
///
/// **This screen owns the socket listener.** It opens one when it appears and
/// closes it when it leaves, when the app goes to the background, and on
/// every failure. That is what makes the narrowed permission a real promise
/// rather than a comment: there is no state in which this app is listening on
/// a port and this screen is not on top.
class SyncReceiveScreen extends ConsumerStatefulWidget {
  const SyncReceiveScreen({super.key});

  @override
  ConsumerState<SyncReceiveScreen> createState() => _SyncReceiveScreenState();
}

class _SyncReceiveScreenState extends ConsumerState<SyncReceiveScreen>
    with WidgetsBindingObserver {
  /// Read once in `initState`: Riverpod 3 does not allow `ref` in `dispose`,
  /// and the port must still be closed there (hard rule 2).
  late final Future<void> Function() _resetSession;
  late final Future<void> Function(bool keepOn) _setKeepScreenOn;

  @override
  void initState() {
    super.initState();
    _resetSession = ref.read(transferSessionProvider).reset;
    _setKeepScreenOn = ref.read(screenSettingsServiceProvider).setKeepScreenOn;
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Leaving the screen closes the port. Not "eventually", not "on the next
    // scan": here, on the way out. The old result goes too, so the next
    // transfer screen opens clean.
    _resetSession();
    _setKeepScreenOn(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Backgrounding closes it too. A listener left open while the phone is in
    // a pocket is exactly the thing this feature promises not to be.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      ref.read(transferSessionProvider).stop();
    }
  }

  Future<void> _start() async {
    await ref
        .read(transferSessionProvider)
        .host(role: ref.read(syncRoleProvider), deviceName: _deviceName());
  }

  /// A label for the other user to recognise, not an identity.
  ///
  /// Deliberately generic: the device model and the owner's name are both
  /// things worth not putting on a screen somebody else is photographing.
  String _deviceName() => 'Gallery';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final session = ref.watch(transferSessionProvider);
    final state = ref.watch(transferStateProvider).value ?? session.state;

    listenToTransfer(ref, _setKeepScreenOn);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.titleSync),
        actions: [
          if (state.phase.isActive)
            TextButton(
              onPressed: () {
                session.cancel();
                session.stop();
              },
              child: Text(l10n.actionSyncStop),
            ),
        ],
      ),
      body: SafeArea(child: _body(l10n, state)),
    );
  }

  Widget _body(AppLocalizations l10n, TransferSessionState state) {
    if (state.phase == SyncPhase.waiting && state.pairing != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            PairingQrCard(
              pairing: state.pairing!,
              manualCode: state.manualCode,
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              l10n.bodySyncWaiting,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }
    return TransferSessionBody(
      state: state,
      endActions: [
        // A new secret and a new port: the old code is never reused.
        FilledButton(
          onPressed: _start,
          child: Text(l10n.actionSyncShowNewCode),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: Text(l10n.actionSyncClose),
        ),
      ],
    );
  }
}

/// Keeps the screen on while a transfer is live, and refreshes the send
/// picker's numbers after each send.
///
/// Called from the build of both transfer screens. A phone that sleeps half
/// way through a large send drops the Wi-Fi and the session with it.
void listenToTransfer(
  WidgetRef ref,
  Future<void> Function(bool keepOn) setKeepScreenOn,
) {
  ref.listen<AsyncValue<TransferSessionState>>(transferStateProvider, (
    previous,
    next,
  ) {
    final before = previous?.value?.phase;
    final now = next.value?.phase;
    if (now == null || now == before) return;

    setKeepScreenOn(now.isActive && now != SyncPhase.waiting);

    // The receiving side indexed the new files itself, outside the normal
    // scan, so the lists must be told. Once per send, after indexing, since
    // the totals are only updated then.
    final refresh = SyncSelectionRules.refreshAfterReceive(
      receivedBefore: previous?.value?.totals.receivedCount ?? 0,
      receivedNow: next.value?.totals.receivedCount ?? 0,
      vaultBefore: previous?.value?.vaultReceivedCount ?? 0,
      vaultNow: next.value?.vaultReceivedCount ?? 0,
    );
    if (next.value?.role == SyncRole.receive) {
      if (refresh.library) {
        ref.read(mediaLibraryVersionProvider.notifier).state++;
        ref.read(albumRevisionProvider.notifier).state++;
        ref.read(tagRevisionProvider.notifier).state++;
      }
      if (refresh.vault) ref.read(vaultRevisionProvider.notifier).state++;
    }

    if (now == SyncPhase.batchDone) {
      final peerId = next.value?.peer?.installId;
      if (peerId != null) ref.invalidate(syncSourcesProvider(peerId));
    }

    // A quick send that delivered files is done with the selection. Cleared
    // here, not when the screen opened, so backing out keeps it.
    final state = next.value;
    if (state != null &&
        state.role == SyncRole.send &&
        (now == SyncPhase.batchDone || now == SyncPhase.done) &&
        state.totals.sentCount > 0 &&
        ref.read(transferPurposeProvider) == TransferPurpose.quickSend) {
      ref.read(selectionProvider.notifier).clear();
    }
  });
}

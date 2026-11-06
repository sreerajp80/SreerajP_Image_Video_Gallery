import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/sync_role.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/transfer_outcome.dart';
import 'package:in_sreerajp_imgvidgal/providers/sync_providers.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/transfer_session_state.dart';
import 'package:in_sreerajp_imgvidgal/widgets/sync/pairing_qr_card.dart';
import 'package:in_sreerajp_imgvidgal/widgets/sync/transfer_progress_view.dart';

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
  late final Future<void> Function() _stopSession;

  @override
  void initState() {
    super.initState();
    _stopSession = ref.read(transferSessionProvider).stop;
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Leaving the screen closes the port. Not "eventually", not "on the next
    // scan": here, on the way out.
    _stopSession();
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
    final role = ref.read(syncRoleProvider);
    final outbox = ref.read(transferOutboxProvider);

    await ref
        .read(transferSessionProvider)
        .host(
          role: role,
          deviceName: _deviceName(),
          toOffer: role == SyncRole.send ? outbox : const [],
        );
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _Body(state: state),
        ),
      ),
    );
  }
}

/// Draws whichever phase the session is in.
class _Body extends StatelessWidget {
  final TransferSessionState state;

  const _Body({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    switch (state.phase) {
      case SyncPhase.idle:
        return const Center(child: CircularProgressIndicator());

      case SyncPhase.waiting:
        final pairing = state.pairing;
        if (pairing == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return SingleChildScrollView(
          child: Column(
            children: [
              PairingQrCard(pairing: pairing, manualCode: state.manualCode),
              const SizedBox(height: 32),
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(l10n.bodySyncWaiting, style: theme.textTheme.bodyMedium),
            ],
          ),
        );

      case SyncPhase.paired:
      case SyncPhase.transferring:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.bodySyncPairedWith(state.peerName),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(l10n.labelSyncTransferring, style: theme.textTheme.bodySmall),
            const SizedBox(height: 32),
            TransferProgressView(progress: state.progress),
          ],
        );

      case SyncPhase.done:
        return _Outcome(state: state);

      case SyncPhase.failed:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                failureMessage(l10n, state.failure),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        );
    }
  }
}

/// What a finished transfer did.
class _Outcome extends StatelessWidget {
  final TransferSessionState state;

  const _Outcome({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final outcome = state.outcome;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 48,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(l10n.labelSyncDone, style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),

          if (outcome != null) ...[
            if (outcome.receivedCount > 0)
              Text(l10n.bodySyncResultReceived(outcome.receivedCount)),
            if (outcome.sentCount > 0)
              Text(l10n.bodySyncResultSent(outcome.sentCount)),
            if (outcome.skippedCount > 0)
              Text(l10n.bodySyncResultSkipped(outcome.skippedCount)),
            if (outcome.failedCount > 0)
              Text(
                l10n.errorSyncResultFailed(outcome.failedCount),
                style: TextStyle(color: theme.colorScheme.error),
              ),
          ],

          if (state.landedInAppFolder) ...[
            const SizedBox(height: 16),
            Text(
              l10n.bodySyncSavedToAppFolder,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Turns a transfer failure into something a person can act on.
///
/// Shared by both transfer screens, so the same failure never gets two
/// different explanations depending on which side of it you were on.
String failureMessage(AppLocalizations l10n, TransferFailure? failure) {
  switch (failure) {
    case TransferFailure.noLocalNetwork:
      return l10n.bodySyncErrorNoNetwork;
    case TransferFailure.pairingTimeout:
      return l10n.bodySyncErrorPairingTimeout;
    case TransferFailure.remoteAddressRefused:
      return l10n.bodySyncErrorRefused;
    case TransferFailure.handshakeRejected:
      return l10n.bodySyncErrorHandshake;
    case TransferFailure.protocolMismatch:
      return l10n.bodySyncErrorProtocol;
    case TransferFailure.connectionLost:
      return l10n.bodySyncErrorConnection;
    case TransferFailure.idleTimeout:
      return l10n.bodySyncErrorIdle;
    case TransferFailure.cancelled:
      return l10n.bodySyncErrorCancelled;
    case TransferFailure.unknown:
    case null:
      return l10n.bodySyncErrorUnknown;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/sync_role.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/transfer_outcome.dart';
import 'package:in_sreerajp_imgvidgal/providers/sync_providers.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/transfer_session_service.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Leaving the screen closes the port. Not "eventually", not "on the next
    // scan": here, on the way out.
    ref.read(transferSessionProvider).stop();
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
    final state = ref.watch(transferStateProvider).valueOrNull ?? session.state;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.syncTitle),
        actions: [
          if (state.phase.isActive)
            TextButton(
              onPressed: () {
                session.cancel();
                session.stop();
              },
              child: Text(l10n.syncStop),
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
              Text(l10n.syncWaiting, style: theme.textTheme.bodyMedium),
            ],
          ),
        );

      case SyncPhase.paired:
      case SyncPhase.transferring:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.syncPairedWith(state.peerName),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(l10n.syncTransferring, style: theme.textTheme.bodySmall),
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
          Text(l10n.syncDone, style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),

          if (outcome != null) ...[
            if (outcome.receivedCount > 0)
              Text(l10n.syncResultReceived(outcome.receivedCount)),
            if (outcome.sentCount > 0)
              Text(l10n.syncResultSent(outcome.sentCount)),
            if (outcome.skippedCount > 0)
              Text(l10n.syncResultSkipped(outcome.skippedCount)),
            if (outcome.failedCount > 0)
              Text(
                l10n.syncResultFailed(outcome.failedCount),
                style: TextStyle(color: theme.colorScheme.error),
              ),
          ],

          if (state.landedInAppFolder) ...[
            const SizedBox(height: 16),
            Text(
              l10n.syncSavedToAppFolder,
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
      return l10n.syncErrorNoNetwork;
    case TransferFailure.pairingTimeout:
      return l10n.syncErrorPairingTimeout;
    case TransferFailure.remoteAddressRefused:
      return l10n.syncErrorRefused;
    case TransferFailure.handshakeRejected:
      return l10n.syncErrorHandshake;
    case TransferFailure.protocolMismatch:
      return l10n.syncErrorProtocol;
    case TransferFailure.connectionLost:
      return l10n.syncErrorConnection;
    case TransferFailure.idleTimeout:
      return l10n.syncErrorIdle;
    case TransferFailure.cancelled:
      return l10n.syncErrorCancelled;
    case TransferFailure.unknown:
    case null:
      return l10n.syncErrorUnknown;
  }
}

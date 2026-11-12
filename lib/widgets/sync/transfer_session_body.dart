import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/sync_role.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/transfer_outcome.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/transfer_purpose.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/transfer_session_state.dart';
import 'package:in_sreerajp_imgvidgal/providers/sync_providers.dart';
import 'package:in_sreerajp_imgvidgal/widgets/sync/app_data_review.dart';
import 'package:in_sreerajp_imgvidgal/widgets/sync/send_picker_view.dart';
import 'package:in_sreerajp_imgvidgal/widgets/sync/transfer_progress_view.dart';

/// Draws a transfer once the phones are paired, for both screens.
///
/// The two transfer screens differ only before pairing (one shows a code,
/// the other scans one). From pairing on, both draw this, so the same phase
/// never looks different depending on which phone showed the code.
class TransferSessionBody extends ConsumerWidget {
  final TransferSessionState state;

  /// What to show when the session failed, under the message. The scan
  /// screen offers "type the code" here.
  final Widget? failureAction;

  /// What to show once the session has ended, done or failed: for example
  /// "Scan another code" and "Close". Without it the screen would be a dead
  /// end, with only the back arrow left.
  final List<Widget> endActions;

  const TransferSessionBody({
    super.key,
    required this.state,
    this.failureAction,
    this.endActions = const <Widget>[],
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final session = ref.read(transferSessionProvider);

    switch (state.phase) {
      case SyncPhase.idle:
      case SyncPhase.waiting:
        return const Center(child: CircularProgressIndicator());

      case SyncPhase.choosing:
      case SyncPhase.batchDone:
        return SendPickerView(
          state: state,
          onSend: (plan) {
            // A quick send offers only the photos picked in the gallery, so
            // once they have all gone there is nothing left to pick. The
            // pairing then ends by itself instead of leaving both phones
            // waiting. Files held back (no room, over the cap) keep it open.
            final isQuickSend =
                ref.read(transferPurposeProvider) == TransferPurpose.quickSend;
            session.sendBatch(
              plan.toSend,
              finishWhenDone: isQuickSend && !plan.hasLeftOver,
            );
          },
          onFinish: () {
            // A phone move sends the vault (if chosen) and then the whole
            // app data and settings, after the last batch of files.
            final isMove =
                ref.read(transferPurposeProvider) == TransferPurpose.phoneMove;
            session.finish(
              withAppData: isMove,
              withVault: isMove && ref.read(phoneMoveIncludeVaultProvider),
            );
          },
        );

      case SyncPhase.appData:
        return _centred(
          children: [
            Text(
              state.role == SyncRole.send
                  ? l10n.bodySyncAppDataSending
                  : l10n.bodySyncAppDataReceiving,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const LinearProgressIndicator(),
          ],
        );

      case SyncPhase.paired:
        // Only the receiver sits here: connected, between sends.
        return _centred(
          children: [
            Text(
              l10n.bodySyncPairedWith(state.peerName),
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              l10n.bodySyncWaitingForSend,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            if (state.batchCount > 0) ...[
              const SizedBox(height: 24),
              _OutcomeLines(outcome: state.totals),
              if (state.totals.failure == TransferFailure.noSpace)
                Text(
                  l10n.bodySyncErrorNoSpace,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              _FolderNote(state: state),
            ],
          ],
        );

      case SyncPhase.preparing:
        return _centred(
          children: [
            Text(l10n.labelSyncPreparing, style: theme.textTheme.titleMedium),
            const SizedBox(height: 24),
            LinearProgressIndicator(
              value: state.progress.filesTotal == 0
                  ? null
                  : state.progress.filesDone / state.progress.filesTotal,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.bodySyncProgressFiles(
                state.progress.filesDone,
                state.progress.filesTotal,
              ),
            ),
          ],
        );

      case SyncPhase.transferring:
        return _centred(
          children: [
            Text(
              l10n.bodySyncPairedWith(state.peerName),
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(l10n.labelSyncTransferring, style: theme.textTheme.bodySmall),
            const SizedBox(height: 32),
            TransferProgressView(progress: state.progress),
          ],
        );

      case SyncPhase.done:
        return _centred(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(l10n.labelSyncDone, style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            _OutcomeLines(outcome: state.totals),
            if (state.vaultReceivedCount > 0)
              Text(l10n.bodySyncVaultReceived(state.vaultReceivedCount)),
            if (state.appDataSent) Text(l10n.bodySyncAppDataSent),
            _FolderNote(state: state),
            if (state.role == SyncRole.receive && state.receivedAppData != null)
              AppDataReview(data: state.receivedAppData!),
            ..._endButtons(),
          ],
        );

      case SyncPhase.failed:
        return _centred(
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              failureMessage(l10n, state.failure),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            if (state.batchCount > 0 || state.outcome != null) ...[
              const SizedBox(height: 16),
              _OutcomeLines(outcome: state.totals),
              _FolderNote(state: state),
            ],
            if (failureAction != null) ...[
              const SizedBox(height: 24),
              failureAction!,
            ],
            ..._endButtons(),
          ],
        );
    }
  }

  List<Widget> _endButtons() {
    if (endActions.isEmpty) return const <Widget>[];
    return <Widget>[
      const SizedBox(height: 24),
      for (final action in endActions)
        Padding(padding: const EdgeInsets.only(top: 8), child: action),
    ];
  }

  static Widget _centred({required List<Widget> children}) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: children,
        ),
      ),
    );
  }
}

/// The counts of a send, one line each.
class _OutcomeLines extends StatelessWidget {
  final TransferOutcome outcome;

  const _OutcomeLines({required this.outcome});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Column(
      children: [
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
    );
  }
}

/// Where received files went, on the receiving phone.
class _FolderNote extends StatelessWidget {
  final TransferSessionState state;

  const _FolderNote({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.role != SyncRole.receive || state.totals.receivedCount == 0) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(
        state.landedInAppFolder
            ? l10n.bodySyncSavedToAppFolder
            : l10n.bodySyncSavedToFolder,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
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
    case TransferFailure.noSpace:
      return l10n.bodySyncErrorNoSpace;
    case TransferFailure.appDataFailed:
      return l10n.bodySyncErrorAppData;
    case TransferFailure.unknown:
    case null:
      return l10n.bodySyncErrorUnknown;
  }
}

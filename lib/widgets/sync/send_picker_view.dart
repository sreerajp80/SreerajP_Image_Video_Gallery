import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/core/domain/sync/sync_selection_rules.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/send_plan.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/sync_role.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/sync_source.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/transfer_outcome.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/transfer_purpose.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/transfer_session_state.dart';
import 'package:in_sreerajp_imgvidgal/providers/sync_providers.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/sync_sources.dart';
import 'package:in_sreerajp_imgvidgal/widgets/common/unit_format_context.dart';

/// Lets the sender tick folders and albums, and shows what the next send
/// will carry.
///
/// Shown after pairing, and again after each send with the same ticks kept,
/// so "Send the rest" is one tap. The numbers come from the marks. In Device
/// Sync a file already sent to this phone is not offered again. In a manual
/// send it is sent again, with a warning, because the user picked it.
class SendPickerView extends ConsumerStatefulWidget {
  final TransferSessionState state;

  /// Called with the plan's files when the user taps Send.
  final void Function(SendPlan plan) onSend;

  /// Called when the user is done and wants to end the pairing.
  final VoidCallback onFinish;

  const SendPickerView({
    super.key,
    required this.state,
    required this.onSend,
    required this.onFinish,
  });

  @override
  ConsumerState<SendPickerView> createState() => _SendPickerViewState();
}

class _SendPickerViewState extends ConsumerState<SendPickerView> {
  /// The ticked sources, by key. Kept across sends.
  final Set<String> _selected = <String>{};

  /// Whether the selection (if any) was ticked for the user once.
  bool _preselected = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final peerId = widget.state.peer?.installId ?? '';
    final sources = ref.watch(syncSourcesProvider(peerId));

    return sources.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(l10n.errorSyncSourcesLoad, textAlign: TextAlign.center),
        ),
      ),
      data: (data) {
        // Photos selected before opening Transfer are ticked to start with.
        if (!_preselected) {
          _preselected = true;
          for (final source in data.sources) {
            if (source.kind == SyncSourceKind.selection) {
              _selected.add(source.key);
            }
          }
        }
        return _content(context, l10n, data);
      },
    );
  }

  Widget _content(
    BuildContext context,
    AppLocalizations l10n,
    SyncSources data,
  ) {
    final theme = Theme.of(context);
    final state = widget.state;
    final purpose = ref.watch(transferPurposeProvider);
    final plan = SyncSelectionRules.plan(
      sources: data.sources,
      selectedKeys: _selected,
      marks: data.marks,
      freeBytes: state.peerFreeBytes,
      allowResend: purpose == TransferPurpose.quickSend,
      // From the session, not this widget: the picker is rebuilt after every
      // send. Only files that arrived are here, so a failed one comes back.
      sentThisSession: state.deliveredIds,
    );

    final selection = data.sources
        .where((s) => s.kind == SyncSourceKind.selection)
        .toList();
    final folders = data.sources
        .where((s) => s.kind == SyncSourceKind.folder)
        .toList();
    final albums = data.sources
        .where((s) => s.kind == SyncSourceKind.album)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (state.phase == SyncPhase.batchDone) ...[
                _BatchResult(state: state),
                const SizedBox(height: 12),
              ],
              Text(l10n.titleSyncPick, style: theme.textTheme.titleMedium),
              if (state.peerFreeBytes != null) ...[
                const SizedBox(height: 4),
                Text(
                  l10n.bodySyncPeerFreeSpace(
                    state.peerName,
                    context.units.bytes(state.peerFreeBytes!),
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              if (purpose == TransferPurpose.phoneMove)
                _PhoneMoveNote(
                  state: state,
                  includeVault: ref.watch(phoneMoveIncludeVaultProvider),
                ),
              for (final source in selection)
                _sourceTile(
                  context,
                  l10n,
                  source,
                  l10n.labelSyncSelectionSource,
                ),
              if (folders.isNotEmpty)
                _sectionHeader(context, l10n.labelSyncFoldersSection),
              for (final source in folders)
                _sourceTile(context, l10n, source, source.name),
              if (albums.isNotEmpty)
                _sectionHeader(context, l10n.labelSyncAlbumsSection),
              for (final source in albums)
                _sourceTile(context, l10n, source, source.name),
            ],
          ),
        ),
        _PlanBar(
          plan: plan,
          anythingTicked: _selected.isNotEmpty,
          isFollowUp: state.batchCount > 0,
          // "The rest" only when every file in this send is new to this
          // pairing. A retry of a failed file is just "Send".
          isRest: SyncSelectionRules.isRest(
            batchCount: state.batchCount,
            toSend: plan.toSend,
            triedIds: state.triedIds,
          ),
          onSend: () => widget.onSend(plan),
          onFinish: widget.onFinish,
        ),
      ],
    );
  }

  Widget _sectionHeader(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _sourceTile(
    BuildContext context,
    AppLocalizations l10n,
    SyncSource source,
    String title,
  ) {
    final ticked = _selected.contains(source.key);
    return CheckboxListTile(
      value: ticked,
      onChanged: (value) => setState(() {
        if (value ?? false) {
          _selected.add(source.key);
        } else {
          _selected.remove(source.key);
        }
      }),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        l10n.bodySyncSourceStats(
          context.units.bytes(source.totalBytes),
          source.sentCount,
          source.itemCount,
        ),
      ),
      secondary: Icon(
        source.allSent
            ? Icons.check_circle_outline
            : (source.kind == SyncSourceKind.album
                  ? Icons.photo_album_outlined
                  : Icons.folder_outlined),
      ),
    );
  }
}

/// Phone move: says what goes on Finish besides the ticked folders and
/// albums.
class _PhoneMoveNote extends StatelessWidget {
  final TransferSessionState state;
  final bool includeVault;

  const _PhoneMoveNote({required this.state, required this.includeVault});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final peerHasVault = state.peer?.vaultReady ?? false;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.settings_backup_restore,
              color: theme.colorScheme.primary,
            ),
            title: Text(l10n.labelSyncAppDataAndSettings),
            subtitle: Text(l10n.bodySyncAppDataOnFinish),
          ),
          if (includeVault)
            ListTile(
              leading: Icon(
                Icons.lock_outline,
                color: peerHasVault
                    ? theme.colorScheme.primary
                    : theme.colorScheme.error,
              ),
              title: Text(l10n.labelSyncIncludeVault),
              subtitle: Text(
                peerHasVault
                    ? l10n.bodySyncIncludeVaultOn
                    : l10n.bodySyncVaultPeerNotReady,
              ),
            ),
        ],
      ),
    );
  }
}

/// What the last send did, above the picker.
class _BatchResult extends StatelessWidget {
  final TransferSessionState state;

  const _BatchResult({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final outcome = state.outcome;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.labelSyncBatchDone, style: theme.textTheme.titleSmall),
            if (outcome != null) ...[
              if (outcome.sentCount > 0)
                Text(l10n.bodySyncResultSent(outcome.sentCount)),
              if (outcome.skippedCount > 0)
                Text(l10n.bodySyncResultSkipped(outcome.skippedCount)),
              if (outcome.failedCount > 0)
                Text(
                  l10n.errorSyncResultFailed(outcome.failedCount),
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              if (outcome.failure == TransferFailure.noSpace)
                Text(
                  l10n.bodySyncErrorNoSpace,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The summary and the buttons at the bottom of the picker.
class _PlanBar extends StatelessWidget {
  final SendPlan plan;
  final bool anythingTicked;
  final bool isFollowUp;

  /// Whether the button says "Send the rest" rather than "Send".
  final bool isRest;
  final VoidCallback onSend;
  final VoidCallback onFinish;

  const _PlanBar({
    required this.plan,
    required this.anythingTicked,
    required this.isFollowUp,
    required this.isRest,
    required this.onSend,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    final lines = <Widget>[];
    if (!anythingTicked) {
      lines.add(Text(l10n.bodySyncPickSomething));
    } else if (plan.isEmpty &&
        !plan.hasLeftOver &&
        (plan.alreadySentCount > 0 || isFollowUp)) {
      // A manual send counts nothing as "already sent", so after its first
      // send the empty plan is told apart by [isFollowUp].
      lines.add(Text(l10n.bodySyncAllSent));
    } else {
      lines.add(
        Text(
          l10n.bodySyncPlanThisSend(
            plan.toSend.length,
            context.units.bytes(plan.sendBytes),
          ),
          style: theme.textTheme.bodyMedium,
        ),
      );
      if (plan.hasLeftOver) {
        lines.add(
          Text(
            l10n.bodySyncPlanLeft(
              plan.leftCount,
              context.units.bytes(plan.leftBytes),
            ),
            style: muted,
          ),
        );
        lines.add(Text(_limitReason(l10n, context), style: muted));
      }
    }
    if (anythingTicked && plan.alreadySentCount > 0) {
      lines.add(
        Text(l10n.bodySyncPlanAlreadySent(plan.alreadySentCount), style: muted),
      );
    }
    if (anythingTicked && plan.resendCount > 0) {
      lines.add(
        Text(
          l10n.bodySyncPlanResend(plan.resendCount),
          style: muted?.copyWith(color: theme.colorScheme.tertiary),
        ),
      );
    }

    return Material(
      elevation: 3,
      color: theme.colorScheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...lines,
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onFinish,
                      child: Text(l10n.actionSyncFinish),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: plan.isEmpty ? null : onSend,
                      child: Text(
                        isRest ? l10n.actionSyncSendRest : l10n.labelSyncSend,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _limitReason(AppLocalizations l10n, BuildContext context) {
    switch (plan.limitedBy) {
      case SendLimit.space:
        return l10n.bodySyncLimitSpace;
      case SendLimit.count:
        return l10n.bodySyncLimitCount(AppConstants.syncMaxManifestEntries);
      case SendLimit.cap:
      case SendLimit.none:
        return l10n.bodySyncLimitCap(
          context.units.bytes(AppConstants.syncSendCapBytes),
        );
    }
  }
}

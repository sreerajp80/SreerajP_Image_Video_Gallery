import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/providers/backup_providers.dart';
import 'package:in_sreerajp_imgvidgal/models/backup/backup_status.dart';
import 'package:in_sreerajp_imgvidgal/models/backup/restore_status.dart';
import 'package:in_sreerajp_imgvidgal/widgets/backup/backup_password_dialog.dart';
import 'package:in_sreerajp_imgvidgal/widgets/backup/restore_preview_sheet.dart';

/// Creates and restores the password-protected `.gallerybak` archive.
///
/// Two halves that never share a code path. Creating asks for a password
/// twice and warns that it cannot be recovered; restoring asks once, shows
/// what would change, and only writes when the user says so.
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _busy = false;

  Future<void> _createBackup() async {
    final l10n = AppLocalizations.of(context)!;

    final password = await BackupPasswordDialog.show(context, isCreating: true);
    if (password == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final result = await ref
          .read(backupControllerProvider.notifier)
          .createBackup(password);

      if (!mounted) return;

      if (result == null) {
        final error = ref.read(backupControllerProvider).error;
        _tell(
          error is BackupException && error.isEmpty
              ? l10n.bodyBackupNothingToSave
              : l10n.errorBackupFailed,
        );
        return;
      }
      // Backing out of the file picker is a normal thing to do, not a fault.
      _tell(
        result.wasCancelled ? l10n.labelBackupCancelled : l10n.labelBackupDone,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restoreBackup() async {
    final l10n = AppLocalizations.of(context)!;

    final password = await BackupPasswordDialog.show(
      context,
      isCreating: false,
    );
    if (password == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final archive = await ref
          .read(restoreControllerProvider.notifier)
          .openArchive(password);

      if (!mounted) return;

      if (archive == null) {
        final error = ref.read(restoreControllerProvider).error;
        // A cancelled picker leaves no error at all; nothing to report.
        if (error != null) _tell(_restoreMessage(l10n, error));
        return;
      }

      // Nothing has been written yet. This is the last point at which
      // walking away costs the user nothing.
      final confirmed = await RestorePreviewSheet.show(context, archive.plan);
      if (confirmed != true) {
        ref.read(restoreControllerProvider.notifier).discard();
        return;
      }

      final summary = await ref
          .read(restoreControllerProvider.notifier)
          .applyOpened();

      if (!mounted) return;
      _tell(summary == null ? l10n.errorRestoreFailed : l10n.labelRestoreDone);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static String _restoreMessage(AppLocalizations l10n, Object error) {
    if (error is! RestoreException) return l10n.errorRestoreFailed;

    switch (error.failure) {
      case RestoreFailure.wrongPasswordOrDamaged:
        return l10n.bodyRestoreWrongPassword;
      case RestoreFailure.notAnArchive:
        return l10n.bodyRestoreNotAnArchive;
      case RestoreFailure.tooLarge:
        return l10n.bodyRestoreTooLarge;
      case RestoreFailure.tooNew:
        return l10n.bodyRestoreTooNew;
      case RestoreFailure.cancelled:
      case RestoreFailure.failed:
        return l10n.errorRestoreFailed;
    }
  }

  void _tell(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stage = ref.watch(backupStageProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.titleBackup)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_busy) ...[
              LinearProgressIndicator(semanticsLabel: _stageLabel(l10n, stage)),
              const SizedBox(height: 8),
              Text(
                _stageLabel(l10n, stage),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
            ],

            _Card(
              icon: Icons.backup_outlined,
              title: l10n.titleBackupCreate,
              body: l10n.bodyBackupCreate,
              actionLabel: l10n.actionBackupCreate,
              onAction: _busy ? null : _createBackup,
            ),
            const SizedBox(height: 16),
            _Card(
              icon: Icons.restore_outlined,
              title: l10n.titleBackupRestore,
              body: l10n.bodyBackupRestore,
              actionLabel: l10n.actionBackupRestore,
              onAction: _busy ? null : _restoreBackup,
            ),
          ],
        ),
      ),
    );
  }

  static String _stageLabel(AppLocalizations l10n, BackupStage? stage) {
    switch (stage) {
      case BackupStage.collecting:
        return l10n.labelBackupStageCollecting;
      case BackupStage.packing:
        return l10n.labelBackupStagePacking;
      case BackupStage.choosingDestination:
        return l10n.bodyBackupStageChoosing;
      case BackupStage.encrypting:
        return l10n.labelBackupStageEncrypting;
      case BackupStage.done:
      case null:
        return l10n.titleBackup;
    }
  }
}

/// One half of the screen.
class _Card extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback? onAction;

  const _Card({
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton(
                onPressed: onAction,
                child: Text(actionLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

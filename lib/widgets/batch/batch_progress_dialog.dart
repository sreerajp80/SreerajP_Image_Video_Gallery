import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/providers/batch_providers.dart';

/// Shows how far a running batch has got, and offers a way to stop it.
///
/// Not dismissible by tapping outside or by the back gesture. A batch writes
/// files, and a dialog that could be flicked away while it worked would leave
/// the user with no way to tell whether it was still running or what it did.
/// Cancel is the way out, and it is always there.
class BatchProgressDialog extends ConsumerWidget {
  const BatchProgressDialog({super.key});

  /// Shows the dialog. Returns when the batch controller closes it.
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const BatchProgressDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final progress = ref.watch(batchProgressProvider);
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(l10n.batchRunning),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              // Indeterminate until there is a real fraction, so the bar does
              // not sit at zero looking stuck while the first file is read.
              value: progress == null || progress.total == 0
                  ? null
                  : progress.fraction,
            ),
            const SizedBox(height: 16),
            if (progress != null)
              Text(
                l10n.batchProgress(progress.done, progress.total),
                style: theme.textTheme.bodyMedium,
              ),
            if (progress?.currentName != null) ...[
              const SizedBox(height: 4),
              Text(
                progress!.currentName!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (progress?.isCancelled ?? false) ...[
              const SizedBox(height: 8),
              Text(
                l10n.batchCancelling,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            // Stops after the file in flight. Nothing half-written is left
            // behind, which is why the batch does not stop instantly.
            onPressed: () =>
                ref.read(batchControllerProvider.notifier).cancel(),
            child: Text(l10n.batchCancel),
          ),
        ],
      ),
    );
  }
}

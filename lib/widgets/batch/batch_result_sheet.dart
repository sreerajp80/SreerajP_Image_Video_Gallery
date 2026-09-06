import 'package:flutter/material.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/batch/batch_outcome.dart';

/// Says what a finished batch actually did.
///
/// It reports failures plainly rather than hiding them behind a cheerful
/// "done". A batch is not all-or-nothing by design, so the user has to be
/// able to see that thirty-nine of forty photos were converted — otherwise
/// the guarantee is worth nothing.
///
/// Counts, not file names: a list of forty names the user cannot act on is
/// not information, it is noise. The first error message is shown once, for
/// a hint at why.
class BatchResultSheet extends StatelessWidget {
  final BatchOutcome outcome;

  const BatchResultSheet({super.key, required this.outcome});

  /// Shows the sheet for [outcome].
  static Future<void> show(BuildContext context, BatchOutcome outcome) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => BatchResultSheet(outcome: outcome),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.batchDone, style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),

            if (outcome.succeededCount > 0)
              _Line(
                icon: Icons.check_circle_outline,
                colour: theme.colorScheme.primary,
                text: l10n.batchResultSucceeded(outcome.succeededCount),
              ),
            if (outcome.failedCount > 0)
              _Line(
                icon: Icons.error_outline,
                colour: theme.colorScheme.error,
                text: l10n.batchResultFailed(outcome.failedCount),
              ),
            if (outcome.skippedCount > 0)
              _Line(
                icon: Icons.remove_circle_outline,
                colour: theme.colorScheme.onSurfaceVariant,
                text: l10n.batchResultSkipped(outcome.skippedCount),
              ),

            if (outcome.firstError != null) ...[
              const SizedBox(height: 12),
              Text(
                outcome.firstError!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],

            const SizedBox(height: 16),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(MaterialLocalizations.of(context).okButtonLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One counted outcome line.
class _Line extends StatelessWidget {
  final IconData icon;
  final Color colour;
  final String text;

  const _Line({required this.icon, required this.colour, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colour),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

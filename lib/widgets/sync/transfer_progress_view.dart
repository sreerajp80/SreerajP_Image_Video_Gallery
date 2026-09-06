import 'package:flutter/material.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/transfer_progress.dart';

/// Shows how far a transfer has got.
///
/// Two readings, because one is not enough to be useful. A bar over files
/// alone sits still for a minute on a large video; a bar over bytes alone
/// hides which file is stuck. Together they say both what is moving and how
/// much is left.
class TransferProgressView extends StatelessWidget {
  final TransferProgress progress;

  const TransferProgressView({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LinearProgressIndicator(
          // Indeterminate until there is a real total, so the bar does not
          // sit at zero looking stuck while the manifest is agreed.
          value: progress.bytesTotal == 0 ? null : progress.fraction,
        ),
        const SizedBox(height: 12),
        Text(
          l10n.syncProgressFiles(progress.filesDone, progress.filesTotal),
          style: theme.textTheme.bodyMedium,
        ),
        if (progress.currentName != null) ...[
          const SizedBox(height: 4),
          Text(
            progress.currentName!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (progress.bytesTotal > 0) ...[
          const SizedBox(height: 4),
          Text(
            '${_size(progress.bytesDone)} / ${_size(progress.bytesTotal)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  /// A short byte size. Digits and units only, so it needs no translation.
  static String _size(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

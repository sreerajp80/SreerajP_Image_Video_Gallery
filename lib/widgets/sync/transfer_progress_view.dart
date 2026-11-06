import 'package:material_ui/material_ui.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/transfer_progress.dart';
import 'package:in_sreerajp_imgvidgal/widgets/common/unit_format_context.dart';

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
          l10n.bodySyncProgressFiles(progress.filesDone, progress.filesTotal),
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
            l10n.bodyTransferBytesProgress(
              context.units.bytes(progress.bytesDone),
              context.units.bytes(progress.bytesTotal),
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

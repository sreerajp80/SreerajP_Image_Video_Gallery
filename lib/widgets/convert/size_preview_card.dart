import 'package:flutter/material.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/convert/size_estimate.dart';
import 'package:in_sreerajp_imgvidgal/services/convert/compression_service.dart';

/// Shows what the converted copy would weigh, before anything is written.
///
/// The numbers come from a real encode at the settings on screen, so this is
/// a preview rather than a guess. While that encode is running the card
/// keeps the last result and shows a thin progress line, which stops the
/// panel from jumping about as the user drags a slider.
class SizePreviewCard extends StatelessWidget {
  /// The most recent estimate, or null when there is none yet.
  final SizeEstimate? estimate;

  /// Size of the original file in bytes.
  final int originalBytes;

  /// Whether a fresh estimate is being worked out right now.
  final bool isWorking;

  /// Whether the last attempt failed.
  final bool hasFailed;

  const SizePreviewCard({
    super.key,
    required this.estimate,
    required this.originalBytes,
    this.isWorking = false,
    this.hasFailed = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final value = estimate;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                _Figure(
                  label: l10n.convertOriginalSize,
                  value: CompressionService.formatBytes(originalBytes),
                ),
                const Icon(Icons.arrow_forward_rounded, size: 18),
                _Figure(
                  label: l10n.convertNewSize,
                  value: value == null
                      ? '—'
                      : CompressionService.formatBytes(value.bytes),
                  emphasis: true,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isWorking)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: <Widget>[
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.convertEstimating,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            if (!isWorking && hasFailed && value == null)
              Text(
                l10n.convertNoEstimate,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            if (value != null) ...<Widget>[
              Text(
                l10n.convertPixelSize(value.width, value.height),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              if (value.isLarger)
                Text(
                  l10n.convertLargerWarning,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                )
              else if (value.savedFraction > 0)
                Text(
                  l10n.convertSmallerBy((value.savedFraction * 100).round()),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
            ],
            const SizedBox(height: 8),
            Text(
              l10n.convertOriginalKept,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One labelled number in the card.
class _Figure extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasis;

  const _Figure({
    required this.label,
    required this.value,
    this.emphasis = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: theme.textTheme.labelSmall),
        const SizedBox(height: 2),
        Text(
          value,
          style: emphasis
              ? theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                )
              : theme.textTheme.titleMedium,
        ),
      ],
    );
  }
}

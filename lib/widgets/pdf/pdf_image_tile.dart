import 'package:flutter/material.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/pdf/pdf_image_entry.dart';

/// One picture found inside a PDF.
///
/// A picture that cannot be pulled out is still shown, greyed out and with the
/// reason underneath. "This PDF has nine pictures and you got seven, here is
/// why" is a much better thing to say than quietly handing over seven.
class PdfImageTile extends StatelessWidget {
  final PdfImageEntry entry;

  /// Whether this one is ticked to save.
  final bool isSelected;

  /// Called when the tile is tapped, for an extractable picture only.
  final VoidCallback? onToggle;

  const PdfImageTile({
    super.key,
    required this.entry,
    required this.isSelected,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final usable = entry.isExtractable;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: usable ? onToggle : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              _preview(context, usable),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.pdfImageSize(entry.width, entry.height),
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      usable
                          ? '${entry.format.extension.toUpperCase()} · '
                                '${_readableSize(entry.byteCount)}'
                          : _skipReason(l10n, entry.skipReason!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: usable
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
              if (usable)
                Checkbox(
                  value: isSelected,
                  onChanged: onToggle == null ? null : (_) => onToggle!(),
                )
              else
                Icon(
                  Icons.block_outlined,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _preview(BuildContext context, bool usable) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 64,
        height: 64,
        child: usable
            ? Image.memory(
                entry.bytes!,
                fit: BoxFit.cover,
                // A picture pulled out of an untrusted PDF may not decode, and
                // that must not take the list down with it.
                errorBuilder: (context, error, stack) => ColoredBox(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.broken_image_outlined),
                ),
              )
            : ColoredBox(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
      ),
    );
  }

  String _readableSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _skipReason(AppLocalizations l10n, PdfImageSkipReason reason) {
    return switch (reason) {
      PdfImageSkipReason.unsupportedFilter => l10n.pdfSkipUnsupportedFilter,
      PdfImageSkipReason.unsupportedColorSpace => l10n.pdfSkipUnsupportedColor,
      PdfImageSkipReason.unsupportedBitDepth => l10n.pdfSkipUnsupportedDepth,
      PdfImageSkipReason.tooLarge => l10n.pdfSkipTooLarge,
      PdfImageSkipReason.malformed => l10n.pdfSkipMalformed,
      PdfImageSkipReason.decodeFailed => l10n.pdfSkipDecodeFailed,
    };
  }
}

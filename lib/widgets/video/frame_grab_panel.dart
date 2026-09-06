import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/convert/image_output_format.dart';
import 'package:in_sreerajp_imgvidgal/widgets/convert/format_chip_row.dart';
import 'package:in_sreerajp_imgvidgal/widgets/video/trim_range_bar.dart';

/// The still-frame tab: a scrubber, the frame under it, and a format choice.
///
/// The preview keeps the last frame that loaded while the next one is being
/// fetched, so dragging the scrubber does not flash an empty box.
class FrameGrabPanel extends StatelessWidget {
  /// The frame under the scrubber, or null when none has loaded.
  final Uint8List? frameBytes;

  /// Where the scrubber is, in milliseconds.
  final int positionMs;

  /// Length of the whole clip, in milliseconds.
  final int clipDurationMs;

  /// Whether a frame is being fetched right now.
  final bool isLoading;

  final ImageOutputFormat format;
  final ValueChanged<int> onPositionChanged;
  final ValueChanged<ImageOutputFormat> onFormatChanged;

  const FrameGrabPanel({
    super.key,
    required this.frameBytes,
    required this.positionMs,
    required this.clipDurationMs,
    required this.format,
    required this.onPositionChanged,
    required this.onFormatChanged,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final max = clipDurationMs <= 0 ? 1.0 : clipDurationMs.toDouble();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: <Widget>[
        AspectRatio(
          aspectRatio: 16 / 9,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: frameBytes == null
                  ? Center(
                      child: isLoading
                          ? const CircularProgressIndicator()
                          : Text(
                              l10n.frameUnavailable,
                              textAlign: TextAlign.center,
                            ),
                    )
                  : Image.memory(
                      frameBytes!,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(l10n.framePositionLabel, style: theme.textTheme.titleSmall),
        Slider(
          value: positionMs.toDouble().clamp(0, max),
          min: 0,
          max: max,
          label: formatDuration(positionMs),
          onChanged: (value) => onPositionChanged(value.round()),
        ),
        Text(
          '${formatDuration(positionMs)} / ${formatDuration(clipDurationMs)}',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 20),
        Text(l10n.frameFormatLabel, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        FormatChipRow(
          selected: format,
          onChanged: onFormatChanged,
          // A frame is a photograph, so only the two formats that suit one
          // are offered here.
          formats: const <ImageOutputFormat>[
            ImageOutputFormat.jpeg,
            ImageOutputFormat.png,
          ],
        ),
      ],
    );
  }
}

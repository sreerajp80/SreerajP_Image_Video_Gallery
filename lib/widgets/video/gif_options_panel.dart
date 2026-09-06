import 'package:flutter/material.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/video/gif_export_options.dart';
import 'package:in_sreerajp_imgvidgal/models/video/trim_range.dart';
import 'package:in_sreerajp_imgvidgal/widgets/video/trim_range_bar.dart';

/// The GIF tab: which part of the clip, how smooth, and how large.
///
/// The frame count under the controls is the honest one, already capped, so
/// the user can see a long selection being shortened before they start.
class GifOptionsPanel extends StatelessWidget {
  final GifExportOptions options;

  /// Length of the whole clip, in milliseconds.
  final int clipDurationMs;

  /// How many frames the current settings would produce.
  final int frameCount;

  /// Whether one of the caps is shortening the result.
  final bool isCapped;

  final ValueChanged<int> onFrameRateChanged;
  final ValueChanged<int> onMaxSideChanged;
  final ValueChanged<bool> onLoopChanged;
  final ValueChanged<TrimRange> onRangeChanged;

  const GifOptionsPanel({
    super.key,
    required this.options,
    required this.clipDurationMs,
    required this.frameCount,
    required this.isCapped,
    required this.onFrameRateChanged,
    required this.onMaxSideChanged,
    required this.onLoopChanged,
    required this.onRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: <Widget>[
        TrimRangeBar(
          range: options.range,
          clipDurationMs: clipDurationMs,
          onStartChanged: (value) =>
              onRangeChanged(options.range.copyWith(startMs: value)),
          onEndChanged: (value) =>
              onRangeChanged(options.range.copyWith(endMs: value)),
        ),
        const SizedBox(height: 20),
        Text(l10n.gifFrameRateLabel, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AppConstants.gifFrameRates
              .map((fps) {
                return ChoiceChip(
                  label: Text('$fps'),
                  selected: options.effectiveFrameRate == fps,
                  onSelected: (selected) {
                    if (selected) onFrameRateChanged(fps);
                  },
                );
              })
              .toList(growable: false),
        ),
        const SizedBox(height: 20),
        Text(l10n.gifSizeLabel, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AppConstants.gifSizeChoices
              .map((side) {
                return ChoiceChip(
                  label: Text('$side'),
                  selected: options.effectiveMaxSide == side,
                  onSelected: (selected) {
                    if (selected) onMaxSideChanged(side);
                  },
                );
              })
              .toList(growable: false),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.gifLoopLabel),
          value: options.loop,
          onChanged: onLoopChanged,
        ),
        const SizedBox(height: 8),
        Text(l10n.gifFrameCount(frameCount), style: theme.textTheme.bodyMedium),
        if (isCapped)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              l10n.gifCapped,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

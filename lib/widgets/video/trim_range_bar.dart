import 'package:flutter/material.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/video/trim_range.dart';

/// A two-handle bar over the whole clip, with the times written under it.
///
/// The widget only reports where the handles were dragged to. Keeping them
/// in order, and keeping the kept slice long enough to be written, is the
/// notifier's job.
class TrimRangeBar extends StatelessWidget {
  final TrimRange range;

  /// Length of the whole clip, in milliseconds.
  final int clipDurationMs;

  final ValueChanged<int> onStartChanged;
  final ValueChanged<int> onEndChanged;

  const TrimRangeBar({
    super.key,
    required this.range,
    required this.clipDurationMs,
    required this.onStartChanged,
    required this.onEndChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final max = clipDurationMs <= 0 ? 1.0 : clipDurationMs.toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        RangeSlider(
          values: RangeValues(
            range.startMs.toDouble().clamp(0, max),
            range.endMs.toDouble().clamp(0, max),
          ),
          min: 0,
          max: max,
          labels: RangeLabels(
            formatDuration(range.startMs),
            formatDuration(range.endMs),
          ),
          onChanged: (values) {
            if (values.start.round() != range.startMs) {
              onStartChanged(values.start.round());
            }
            if (values.end.round() != range.endMs) {
              onEndChanged(values.end.round());
            }
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            _Figure(
              label: l10n.trimStartLabel,
              value: formatDuration(range.startMs),
            ),
            _Figure(
              label: l10n.trimLengthLabel,
              value: formatDuration(range.durationMs),
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            _Figure(
              label: l10n.trimEndLabel,
              value: formatDuration(range.endMs),
            ),
          ],
        ),
      ],
    );
  }
}

/// Formats a millisecond count as `m:ss` or `h:mm:ss`.
///
/// Digits and colons read the same in every language the app ships, so this
/// is built here rather than pulled from a translated string.
String formatDuration(int milliseconds) {
  final safe = milliseconds < 0 ? 0 : milliseconds;
  final totalSeconds = safe ~/ 1000;
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;

  final secondsText = seconds.toString().padLeft(2, '0');
  if (hours == 0) return '$minutes:$secondsText';
  return '$hours:${minutes.toString().padLeft(2, '0')}:$secondsText';
}

class _Figure extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? style;

  const _Figure({required this.label, required this.value, this.style});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: theme.textTheme.labelSmall),
        Text(value, style: style ?? theme.textTheme.titleSmall),
      ],
    );
  }
}

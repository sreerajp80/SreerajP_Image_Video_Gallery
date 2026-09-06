import 'package:flutter/material.dart';

/// One labelled slider, used by every tool panel in the editor.
///
/// Having a single row widget keeps the panels short and makes every slider
/// behave the same: same label placement, same value readout, same reset on
/// a long press.
class EditorSliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;

  /// Value a long press puts the slider back to.
  final double neutral;

  final ValueChanged<double> onChanged;

  /// Called once when the finger lifts, so a change lands in undo as one step
  /// rather than as one step per pixel of movement.
  final ValueChanged<double>? onChangeEnd;

  /// How the value is shown to the right of the label.
  final String Function(double value)? formatValue;

  const EditorSliderRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = -1,
    this.max = 1,
    this.neutral = 0,
    this.onChangeEnd,
    this.formatValue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = formatValue?.call(value) ?? (value * 100).round().toString();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: theme.textTheme.labelLarge),
              Text(
                text,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          GestureDetector(
            // A long press is the quick way back to neutral without hunting
            // for the exact middle of the track.
            onLongPress: () {
              onChanged(neutral);
              onChangeEnd?.call(neutral);
            },
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
              onChangeEnd: onChangeEnd,
            ),
          ),
        ],
      ),
    );
  }
}

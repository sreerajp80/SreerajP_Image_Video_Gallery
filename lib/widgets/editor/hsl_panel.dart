import 'package:flutter/material.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/hsl_adjustments.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/tone_adjustments.dart';
import 'package:in_sreerajp_imgvidgal/widgets/editor/editor_slider_row.dart';

/// The 8-channel HSL colour tuner, shown inside the Tune panel.
///
/// Eight coloured chips let the user pick a colour range. Three sliders
/// (Hue, Saturation, Luminance) adjust only that range. Changes are
/// always additive and non-destructive, following the same pattern as
/// the tone sliders.
class HslPanel extends StatefulWidget {
  final ToneAdjustments adjustments;
  final ValueChanged<ToneAdjustments> onChanged;
  final ValueChanged<ToneAdjustments> onChangeEnd;
  final VoidCallback onReset;

  const HslPanel({
    super.key,
    required this.adjustments,
    required this.onChanged,
    required this.onChangeEnd,
    required this.onReset,
  });

  @override
  State<HslPanel> createState() => _HslPanelState();
}

class _HslPanelState extends State<HslPanel> {
  HslColorRange _activeRange = HslColorRange.red;

  static const Map<HslColorRange, Color> _rangeColors = {
    HslColorRange.red: Color(0xFFE53935),
    HslColorRange.orange: Color(0xFFFF9800),
    HslColorRange.yellow: Color(0xFFFFEB3B),
    HslColorRange.green: Color(0xFF43A047),
    HslColorRange.cyan: Color(0xFF00BCD4),
    HslColorRange.blue: Color(0xFF1E88E5),
    HslColorRange.purple: Color(0xFF7B1FA2),
    HslColorRange.magenta: Color(0xFFE91E63),
  };

  HslChannelAdjustment get _adjustment =>
      widget.adjustments.hslAdjustments.adjustmentFor(_activeRange);

  ToneAdjustments _withHsl(HslChannelAdjustment adj) {
    return widget.adjustments.copyWith(
      hslAdjustments: widget.adjustments.hslAdjustments.copyWithChannel(
        _activeRange,
        adj,
      ),
    );
  }

  String _rangeName(AppLocalizations l10n, HslColorRange range) {
    switch (range) {
      case HslColorRange.red:
        return l10n.hslRangeRed;
      case HslColorRange.orange:
        return l10n.hslRangeOrange;
      case HslColorRange.yellow:
        return l10n.hslRangeYellow;
      case HslColorRange.green:
        return l10n.hslRangeGreen;
      case HslColorRange.cyan:
        return l10n.hslRangeCyan;
      case HslColorRange.blue:
        return l10n.hslRangeBlue;
      case HslColorRange.purple:
        return l10n.hslRangePurple;
      case HslColorRange.magenta:
        return l10n.hslRangeMagenta;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final adj = _adjustment;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section header.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.hslTitle, style: theme.textTheme.labelLarge),
              if (!widget.adjustments.hslAdjustments.isNeutral)
                TextButton(
                  onPressed: widget.onReset,
                  child: Text(l10n.hslReset),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Color range selector: 8 coloured circles.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: HslColorRange.values.map((range) {
              final isActive = range == _activeRange;
              final color = _rangeColors[range]!;
              final hasChange = !widget.adjustments.hslAdjustments
                  .adjustmentFor(range)
                  .isNeutral;

              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () => setState(() => _activeRange = range),
                  child: Tooltip(
                    message: _rangeName(l10n, range),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: isActive ? 40 : 32,
                      height: isActive ? 40 : 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isActive
                            ? Border.all(
                                color: theme.colorScheme.onSurface,
                                width: 2.5,
                              )
                            : null,
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                      child: hasChange
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 4),

        // Current range name.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            _rangeName(l10n, _activeRange),
            style: theme.textTheme.bodySmall?.copyWith(
              color: _rangeColors[_activeRange],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 4),

        // Hue slider.
        EditorSliderRow(
          label: l10n.hslHue,
          value: adj.hue,
          onChanged: (v) => widget.onChanged(_withHsl(adj.copyWith(hue: v))),
          onChangeEnd: (v) =>
              widget.onChangeEnd(_withHsl(adj.copyWith(hue: v))),
        ),

        // Saturation slider.
        EditorSliderRow(
          label: l10n.hslSaturation,
          value: adj.saturation,
          onChanged: (v) =>
              widget.onChanged(_withHsl(adj.copyWith(saturation: v))),
          onChangeEnd: (v) =>
              widget.onChangeEnd(_withHsl(adj.copyWith(saturation: v))),
        ),

        // Luminance slider.
        EditorSliderRow(
          label: l10n.hslLuminance,
          value: adj.luminance,
          onChanged: (v) =>
              widget.onChanged(_withHsl(adj.copyWith(luminance: v))),
          onChangeEnd: (v) =>
              widget.onChangeEnd(_withHsl(adj.copyWith(luminance: v))),
        ),
      ],
    );
  }
}

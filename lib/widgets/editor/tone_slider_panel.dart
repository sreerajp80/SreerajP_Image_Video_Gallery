import 'package:flutter/material.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/hsl_adjustments.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/tone_adjustments.dart';
import 'package:in_sreerajp_imgvidgal/widgets/editor/curve_editor.dart';
import 'package:in_sreerajp_imgvidgal/widgets/editor/editor_slider_row.dart';
import 'package:in_sreerajp_imgvidgal/widgets/editor/hsl_panel.dart';

/// The light and colour panel: eight sliders, the RGB curves, and the
/// 8-channel HSL colour tuner.
///
/// It never edits pixels. Every move produces a new [ToneAdjustments] and
/// hands it back, and the screen decides what to do with it.
class ToneSliderPanel extends StatelessWidget {
  final ToneAdjustments adjustments;

  /// Called while a slider moves, for the live preview.
  final ValueChanged<ToneAdjustments> onChanged;

  /// Called when a slider is let go, so undo gets one step per gesture.
  final ValueChanged<ToneAdjustments> onChangeEnd;

  final VoidCallback onReset;

  const ToneSliderPanel({
    super.key,
    required this.adjustments,
    required this.onChanged,
    required this.onChangeEnd,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    Widget slider(
      String label,
      double value,
      ToneAdjustments Function(double value) build,
    ) {
      return EditorSliderRow(
        label: label,
        value: value,
        onChanged: (next) => onChanged(build(next)),
        onChangeEnd: (next) => onChangeEnd(build(next)),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        slider(
          l10n.toneExposure,
          adjustments.exposure,
          (v) => adjustments.copyWith(exposure: v),
        ),
        slider(
          l10n.toneContrast,
          adjustments.contrast,
          (v) => adjustments.copyWith(contrast: v),
        ),
        slider(
          l10n.toneHighlights,
          adjustments.highlights,
          (v) => adjustments.copyWith(highlights: v),
        ),
        slider(
          l10n.toneShadows,
          adjustments.shadows,
          (v) => adjustments.copyWith(shadows: v),
        ),
        slider(
          l10n.toneTemperature,
          adjustments.temperature,
          (v) => adjustments.copyWith(temperature: v),
        ),
        slider(
          l10n.toneTint,
          adjustments.tint,
          (v) => adjustments.copyWith(tint: v),
        ),
        slider(
          l10n.toneVibrance,
          adjustments.vibrance,
          (v) => adjustments.copyWith(vibrance: v),
        ),
        slider(
          l10n.toneSaturation,
          adjustments.saturation,
          (v) => adjustments.copyWith(saturation: v),
        ),
        const Divider(height: 24),
        CurveEditor(adjustments: adjustments, onChanged: onChangeEnd),
        const Divider(height: 24),
        HslPanel(
          adjustments: adjustments,
          onChanged: onChanged,
          onChangeEnd: onChangeEnd,
          onReset: () => onChangeEnd(
            adjustments.copyWith(hslAdjustments: HslAdjustments.neutral),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.restart_alt),
              label: Text(l10n.toneReset),
            ),
          ),
        ),
      ],
    );
  }
}

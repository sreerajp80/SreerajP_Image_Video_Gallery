import 'package:in_sreerajp_imgvidgal/models/editor/filter_preset.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/tone_adjustments.dart';

/// What one preset actually does to a photo.
///
/// A preset is only ever a set of tone settings plus an optional drain of
/// colour and an optional colour cast. Keeping it to that means the renderer
/// has a single code path for filters and for hand-moved sliders.
class FilterDefinition {
  /// The slider positions this look is built from.
  final ToneAdjustments adjustments;

  /// Whether the colour is drained out before the cast is applied.
  final bool monochrome;

  /// Colour the image is pulled toward, as a 32 bit ARGB value.
  final int tintArgb;

  /// How far the image is pulled toward [tintArgb], 0 to 1.
  final double tintStrength;

  const FilterDefinition({
    this.adjustments = ToneAdjustments.neutral,
    this.monochrome = false,
    this.tintArgb = 0xFF808080,
    this.tintStrength = 0,
  });

  /// Whether this definition would leave the photo untouched.
  bool get isNeutral =>
      adjustments.isNeutral && !monochrome && tintStrength <= 0;
}

/// The catalogue of one-tap looks and what each one means.
///
/// The looks live here rather than in the model so they can be retuned
/// without breaking a session that was saved earlier.
class FilterPresetService {
  const FilterPresetService();

  /// Every preset, in the order the filter strip shows them.
  List<FilterPresetId> get presets => FilterPresetId.values;

  /// The full-strength definition of [id].
  FilterDefinition definitionFor(FilterPresetId id) {
    switch (id) {
      case FilterPresetId.none:
        return const FilterDefinition();

      case FilterPresetId.mono:
        return const FilterDefinition(
          monochrome: true,
          adjustments: ToneAdjustments(contrast: 0.15),
        );

      case FilterPresetId.sepia:
        return const FilterDefinition(
          monochrome: true,
          tintArgb: 0xFFA0784B,
          tintStrength: 0.55,
          adjustments: ToneAdjustments(contrast: 0.1, exposure: 0.05),
        );

      case FilterPresetId.vintage:
        return const FilterDefinition(
          tintArgb: 0xFFC8A26E,
          tintStrength: 0.28,
          adjustments: ToneAdjustments(
            contrast: -0.12,
            shadows: 0.22,
            saturation: -0.2,
            temperature: 0.18,
          ),
        );

      case FilterPresetId.vivid:
        return const FilterDefinition(
          adjustments: ToneAdjustments(
            contrast: 0.25,
            vibrance: 0.45,
            saturation: 0.15,
          ),
        );

      case FilterPresetId.cool:
        return const FilterDefinition(
          adjustments: ToneAdjustments(
            temperature: -0.35,
            tint: -0.1,
            contrast: 0.08,
          ),
        );

      case FilterPresetId.warm:
        return const FilterDefinition(
          adjustments: ToneAdjustments(
            temperature: 0.35,
            tint: 0.08,
            contrast: 0.08,
          ),
        );

      case FilterPresetId.fade:
        return const FilterDefinition(
          adjustments: ToneAdjustments(
            contrast: -0.25,
            shadows: 0.35,
            saturation: -0.25,
          ),
        );
    }
  }

  /// The definition of [preset] scaled by how far the intensity slider is up.
  ///
  /// At intensity 0 the result is neutral, so a preset can always be dialled
  /// back to the original photo without having to pick "none".
  FilterDefinition resolve(FilterPreset preset) {
    if (preset.isNone) return const FilterDefinition();

    final intensity = preset.intensity.isNaN
        ? 1.0
        : preset.intensity.clamp(0.0, 1.0);
    if (intensity <= 0) return const FilterDefinition();

    final base = definitionFor(preset.id);
    if (intensity >= 1) return base;

    double scale(double value) => value * intensity;

    return FilterDefinition(
      monochrome: base.monochrome,
      tintArgb: base.tintArgb,
      // A partly applied mono look is expressed as a partial tint pull, which
      // the renderer already knows how to blend.
      tintStrength: base.tintStrength * intensity,
      adjustments: base.adjustments.copyWith(
        exposure: scale(base.adjustments.exposure),
        contrast: scale(base.adjustments.contrast),
        highlights: scale(base.adjustments.highlights),
        shadows: scale(base.adjustments.shadows),
        temperature: scale(base.adjustments.temperature),
        tint: scale(base.adjustments.tint),
        vibrance: scale(base.adjustments.vibrance),
        saturation: scale(base.adjustments.saturation),
      ),
    );
  }

  /// How strongly the colour should be drained for [preset].
  ///
  /// A monochrome preset at half intensity is half grey rather than fully
  /// grey, so the strip's intensity slider works on every look.
  double monochromeStrength(FilterPreset preset) {
    if (preset.isNone) return 0;
    if (!definitionFor(preset.id).monochrome) return 0;
    if (preset.intensity.isNaN) return 1;
    return preset.intensity.clamp(0.0, 1.0);
  }
}

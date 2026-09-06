import 'package:flutter/foundation.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/tone_curve.dart';

/// Every light and colour slider in the editor, as one immutable value.
///
/// All sliders run from -1 to 1 with 0 meaning "leave it alone", except the
/// curves. Keeping one neutral value for every field makes [isNeutral] cheap,
/// which lets the renderer skip the whole tone stage when nothing was moved.
@immutable
class ToneAdjustments {
  /// Overall brightness, -1 (dark) to 1 (bright).
  final double exposure;

  /// Difference between light and dark areas, -1 to 1.
  final double contrast;

  /// Brightness of the light areas only, -1 to 1.
  final double highlights;

  /// Brightness of the dark areas only, -1 to 1.
  final double shadows;

  /// Warm or cool cast, -1 (cool blue) to 1 (warm orange).
  final double temperature;

  /// Green or magenta cast, -1 (green) to 1 (magenta).
  final double tint;

  /// Boost for the duller colours only, -1 to 1.
  final double vibrance;

  /// Boost for every colour equally, -1 (grey) to 1.
  final double saturation;

  /// Red channel curve.
  final ToneCurve redCurve;

  /// Green channel curve.
  final ToneCurve greenCurve;

  /// Blue channel curve.
  final ToneCurve blueCurve;

  /// Curve applied to all three channels together.
  final ToneCurve rgbCurve;

  const ToneAdjustments({
    this.exposure = 0,
    this.contrast = 0,
    this.highlights = 0,
    this.shadows = 0,
    this.temperature = 0,
    this.tint = 0,
    this.vibrance = 0,
    this.saturation = 0,
    this.redCurve = ToneCurve.linear,
    this.greenCurve = ToneCurve.linear,
    this.blueCurve = ToneCurve.linear,
    this.rgbCurve = ToneCurve.linear,
  });

  /// Nothing changed.
  static const ToneAdjustments neutral = ToneAdjustments();

  /// Whether every slider and curve is still at its neutral position.
  bool get isNeutral =>
      exposure == 0 &&
      contrast == 0 &&
      highlights == 0 &&
      shadows == 0 &&
      temperature == 0 &&
      tint == 0 &&
      vibrance == 0 &&
      saturation == 0 &&
      redCurve.isLinear &&
      greenCurve.isLinear &&
      blueCurve.isLinear &&
      rgbCurve.isLinear;

  /// Whether any of the four curves was edited.
  bool get hasCurves =>
      !redCurve.isLinear ||
      !greenCurve.isLinear ||
      !blueCurve.isLinear ||
      !rgbCurve.isLinear;

  ToneAdjustments copyWith({
    double? exposure,
    double? contrast,
    double? highlights,
    double? shadows,
    double? temperature,
    double? tint,
    double? vibrance,
    double? saturation,
    ToneCurve? redCurve,
    ToneCurve? greenCurve,
    ToneCurve? blueCurve,
    ToneCurve? rgbCurve,
  }) {
    return ToneAdjustments(
      exposure: exposure ?? this.exposure,
      contrast: contrast ?? this.contrast,
      highlights: highlights ?? this.highlights,
      shadows: shadows ?? this.shadows,
      temperature: temperature ?? this.temperature,
      tint: tint ?? this.tint,
      vibrance: vibrance ?? this.vibrance,
      saturation: saturation ?? this.saturation,
      redCurve: redCurve ?? this.redCurve,
      greenCurve: greenCurve ?? this.greenCurve,
      blueCurve: blueCurve ?? this.blueCurve,
      rgbCurve: rgbCurve ?? this.rgbCurve,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'exposure': exposure,
    'contrast': contrast,
    'highlights': highlights,
    'shadows': shadows,
    'temperature': temperature,
    'tint': tint,
    'vibrance': vibrance,
    'saturation': saturation,
    'redCurve': redCurve.toMap(),
    'greenCurve': greenCurve.toMap(),
    'blueCurve': blueCurve.toMap(),
    'rgbCurve': rgbCurve.toMap(),
  };

  factory ToneAdjustments.fromMap(Map<String, dynamic> map) {
    ToneCurve readCurve(String key) {
      final raw = map[key];
      if (raw is Map) {
        return ToneCurve.fromMap(Map<String, dynamic>.from(raw));
      }
      return ToneCurve.linear;
    }

    return ToneAdjustments(
      exposure: (map['exposure'] as num?)?.toDouble() ?? 0,
      contrast: (map['contrast'] as num?)?.toDouble() ?? 0,
      highlights: (map['highlights'] as num?)?.toDouble() ?? 0,
      shadows: (map['shadows'] as num?)?.toDouble() ?? 0,
      temperature: (map['temperature'] as num?)?.toDouble() ?? 0,
      tint: (map['tint'] as num?)?.toDouble() ?? 0,
      vibrance: (map['vibrance'] as num?)?.toDouble() ?? 0,
      saturation: (map['saturation'] as num?)?.toDouble() ?? 0,
      redCurve: readCurve('redCurve'),
      greenCurve: readCurve('greenCurve'),
      blueCurve: readCurve('blueCurve'),
      rgbCurve: readCurve('rgbCurve'),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ToneAdjustments &&
          runtimeType == other.runtimeType &&
          exposure == other.exposure &&
          contrast == other.contrast &&
          highlights == other.highlights &&
          shadows == other.shadows &&
          temperature == other.temperature &&
          tint == other.tint &&
          vibrance == other.vibrance &&
          saturation == other.saturation &&
          redCurve == other.redCurve &&
          greenCurve == other.greenCurve &&
          blueCurve == other.blueCurve &&
          rgbCurve == other.rgbCurve;

  @override
  int get hashCode => Object.hash(
    exposure,
    contrast,
    highlights,
    shadows,
    temperature,
    tint,
    vibrance,
    saturation,
    redCurve,
    greenCurve,
    blueCurve,
    rgbCurve,
  );

  @override
  String toString() =>
      'ToneAdjustments(exposure: $exposure, contrast: $contrast, '
      'highlights: $highlights, shadows: $shadows, '
      'temperature: $temperature, tint: $tint, vibrance: $vibrance, '
      'saturation: $saturation)';
}

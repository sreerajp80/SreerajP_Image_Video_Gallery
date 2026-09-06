import 'dart:math' as math;
import 'dart:typed_data';

import 'package:in_sreerajp_imgvidgal/models/editor/tone_adjustments.dart';
import 'package:in_sreerajp_imgvidgal/services/editor/tone_curve_service.dart';

/// One lookup table per channel, plus the two settings that cannot be baked
/// into a table.
///
/// Vibrance and saturation compare the three channels against each other, so
/// they have to be worked out per pixel. Everything else is a plain table
/// read.
class ToneLookupTables {
  final Uint8List red;
  final Uint8List green;
  final Uint8List blue;

  /// Saturation from -1 to 1, already sanitised.
  final double saturation;

  /// Vibrance from -1 to 1, already sanitised.
  final double vibrance;

  const ToneLookupTables({
    required this.red,
    required this.green,
    required this.blue,
    this.saturation = 0,
    this.vibrance = 0,
  });

  /// Whether the per-pixel colour stage has anything to do.
  bool get needsColorPass => saturation != 0 || vibrance != 0;

  /// Whether the tables would leave every channel exactly as it was.
  bool get isIdentity {
    if (needsColorPass) return false;
    for (var i = 0; i < 256; i++) {
      if (red[i] != i || green[i] != i || blue[i] != i) return false;
    }
    return true;
  }
}

/// Builds the lookup tables the renderer applies for the tone sliders.
///
/// Every slider is defined here as a pure function of a 0 to 255 input, so
/// the exact effect of each control can be tested without decoding a photo.
class ToneAdjustmentService {
  final ToneCurveService _curveService;

  const ToneAdjustmentService({
    ToneCurveService curveService = const ToneCurveService(),
  }) : _curveService = curveService;

  /// Builds the three channel tables for [adjustments].
  ///
  /// The order inside a channel is fixed: exposure, then contrast, then
  /// highlights and shadows, then the white balance shift, then the curves.
  /// Doing white balance before the curves means a curve the user drew still
  /// behaves the way the on-screen graph showed it.
  ToneLookupTables buildTables(ToneAdjustments adjustments) {
    final exposure = _sanitize(adjustments.exposure);
    final contrast = _sanitize(adjustments.contrast);
    final highlights = _sanitize(adjustments.highlights);
    final shadows = _sanitize(adjustments.shadows);
    final temperature = _sanitize(adjustments.temperature);
    final tint = _sanitize(adjustments.tint);

    final rgbTable = _curveService.buildTable(adjustments.rgbCurve);
    final redCurve = _curveService.buildTable(adjustments.redCurve);
    final greenCurve = _curveService.buildTable(adjustments.greenCurve);
    final blueCurve = _curveService.buildTable(adjustments.blueCurve);

    // Warmer pushes red up and blue down; tint trades green against the
    // red and blue pair. Both are gentle, so a full slider is still usable.
    final redShift = temperature * 30 - tint * 12;
    final greenShift = tint * 24;
    final blueShift = -temperature * 30 - tint * 12;

    Uint8List channel(double shift, Uint8List curve) {
      final table = Uint8List(256);
      for (var i = 0; i < 256; i++) {
        var value = i.toDouble();
        value = _applyExposure(value, exposure);
        value = _applyContrast(value, contrast);
        value = _applyHighlights(value, highlights);
        value = _applyShadows(value, shadows);
        value = (value + shift).clamp(0.0, 255.0);

        final afterRgb = rgbTable[value.round().clamp(0, 255)];
        table[i] = curve[afterRgb];
      }
      return table;
    }

    return ToneLookupTables(
      red: channel(redShift, redCurve),
      green: channel(greenShift, greenCurve),
      blue: channel(blueShift, blueCurve),
      saturation: _sanitize(adjustments.saturation),
      vibrance: _sanitize(adjustments.vibrance),
    );
  }

  /// Brightness. Doubling on a full positive slider, halving on a full
  /// negative one, which matches how a one stop exposure change behaves.
  double applyExposure(double value, double amount) =>
      _applyExposure(value, _sanitize(amount));

  /// Contrast, pivoted around mid grey so the picture does not also get
  /// brighter or darker.
  double applyContrast(double value, double amount) =>
      _applyContrast(value, _sanitize(amount));

  /// Highlights, which only moves the bright end of the range.
  double applyHighlights(double value, double amount) =>
      _applyHighlights(value, _sanitize(amount));

  /// Shadows, which only moves the dark end of the range.
  double applyShadows(double value, double amount) =>
      _applyShadows(value, _sanitize(amount));

  /// The perceived brightness of one pixel, 0 to 255.
  ///
  /// Green counts most and blue least, because that is how the eye works.
  /// Saturation and vibrance both pull colours toward this value.
  double luminance(int red, int green, int blue) =>
      0.299 * red + 0.587 * green + 0.114 * blue;

  /// Applies saturation and vibrance to one pixel.
  ///
  /// Saturation moves every colour the same amount. Vibrance leans on the
  /// duller colours and mostly leaves already vivid ones alone, which is what
  /// keeps skin tones from going orange.
  List<int> applyColor(
    int red,
    int green,
    int blue,
    double saturation,
    double vibrance,
  ) {
    final sat = _sanitize(saturation);
    final vib = _sanitize(vibrance);
    if (sat == 0 && vib == 0) return <int>[red, green, blue];

    final grey = luminance(red, green, blue);

    var factor = 1 + sat;
    if (vib != 0) {
      final maxChannel = math.max(red, math.max(green, blue));
      final minChannel = math.min(red, math.min(green, blue));
      // How colourful the pixel already is, 0 (grey) to 1 (pure colour).
      final currentSaturation = maxChannel == 0
          ? 0.0
          : (maxChannel - minChannel) / maxChannel;
      factor += vib * (1 - currentSaturation);
    }

    int mix(int channel) =>
        (grey + (channel - grey) * factor).round().clamp(0, 255);

    return <int>[mix(red), mix(green), mix(blue)];
  }

  double _applyExposure(double value, double amount) {
    if (amount == 0) return value;
    // 2^amount: +1 doubles the light, -1 halves it.
    final gain = math.pow(2, amount).toDouble();
    return (value * gain).clamp(0.0, 255.0);
  }

  double _applyContrast(double value, double amount) {
    if (amount == 0) return value;
    final factor = 1 + amount;
    return ((value - 128) * factor + 128).clamp(0.0, 255.0);
  }

  double _applyHighlights(double value, double amount) {
    if (amount == 0) return value;
    // Weight rises from 0 at mid grey to 1 at white, so the dark half of the
    // picture is untouched.
    final weight = ((value - 128) / 127).clamp(0.0, 1.0);
    return (value + amount * 64 * weight).clamp(0.0, 255.0);
  }

  double _applyShadows(double value, double amount) {
    if (amount == 0) return value;
    // Mirror of the highlights weight: 1 at black, 0 at mid grey.
    final weight = ((128 - value) / 128).clamp(0.0, 1.0);
    return (value + amount * 64 * weight).clamp(0.0, 255.0);
  }

  /// Pulls a slider value into -1 to 1 and turns any NaN into 0.
  double _sanitize(double value) {
    if (value.isNaN || value.isInfinite) return 0;
    return value.clamp(-1.0, 1.0);
  }
}

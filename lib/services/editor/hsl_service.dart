import 'dart:math' as math;

import 'package:image/image.dart' as img;
import 'package:in_sreerajp_imgvidgal/models/editor/hsl_adjustments.dart';

/// Maps the 8 colour ranges to hue bands and applies per-range H/S/L shifts.
///
/// Each range has a centre hue and a half-width. Pixels whose hue falls
/// inside the band get the full adjustment; pixels near the border get a
/// smooth blend so adjacent colours never show a hard seam.
class HslService {
  const HslService();

  /// Centre hue in degrees for each colour range.
  static const Map<HslColorRange, double> _centreHues = {
    HslColorRange.red: 0,
    HslColorRange.orange: 30,
    HslColorRange.yellow: 60,
    HslColorRange.green: 120,
    HslColorRange.cyan: 180,
    HslColorRange.blue: 240,
    HslColorRange.purple: 285,
    HslColorRange.magenta: 330,
  };

  /// Half-width of each colour band in degrees.
  ///
  /// The bands overlap at their edges, which is where the smooth falloff
  /// avoids hard seams between adjacent ranges.
  static const Map<HslColorRange, double> _halfWidths = {
    HslColorRange.red: 15,
    HslColorRange.orange: 15,
    HslColorRange.yellow: 15,
    HslColorRange.green: 45,
    HslColorRange.cyan: 15,
    HslColorRange.blue: 45,
    HslColorRange.purple: 15,
    HslColorRange.magenta: 15,
  };

  /// How strongly a pixel at [hueDegrees] belongs to [range].
  ///
  /// Returns 1.0 at the centre of the band, falling to 0.0 at and beyond
  /// the edge. The falloff is a smoothstep so the blend looks natural.
  double rangeWeight(double hueDegrees, HslColorRange range) {
    final centre = _centreHues[range]!;
    final halfWidth = _halfWidths[range]!;

    // Shortest angular distance, wrapping around 360°.
    var delta = (hueDegrees - centre) % 360;
    if (delta > 180) delta -= 360;
    if (delta < -180) delta += 360;

    final distance = delta.abs();
    if (distance >= halfWidth) return 0;

    // Smoothstep falloff inside the band.
    final t = distance / halfWidth; // 0 at centre, 1 at edge
    // 1 - smoothstep(t) = 1 - (3t² - 2t³)
    return 1 - t * t * (3 - 2 * t);
  }

  /// Applies all non-neutral HSL adjustments to [image] in place.
  ///
  /// Achromatic pixels (very low saturation) are skipped because hue is
  /// undefined for greys and shifting them would add false colour.
  img.Image applyHsl(img.Image image, HslAdjustments adjustments) {
    if (adjustments.isNeutral) return image;

    // Collect only the ranges the user actually touched.
    final active = <HslColorRange, HslChannelAdjustment>{};
    for (final range in HslColorRange.values) {
      final adj = adjustments.adjustmentFor(range);
      if (!adj.isNeutral) active[range] = adj;
    }
    if (active.isEmpty) return image;

    for (final pixel in image) {
      final r = pixel.r.round().clamp(0, 255);
      final g = pixel.g.round().clamp(0, 255);
      final b = pixel.b.round().clamp(0, 255);

      final hsl = _rgbToHsl(r, g, b);
      final hue = hsl[0]; // 0–360
      final sat = hsl[1]; // 0–1
      final lum = hsl[2]; // 0–1

      // Skip near-achromatic pixels: hue is meaningless.
      if (sat < 0.04) continue;

      var hueShift = 0.0;
      var satShift = 0.0;
      var lumShift = 0.0;

      for (final entry in active.entries) {
        final w = rangeWeight(hue, entry.key);
        if (w <= 0) continue;
        final adj = entry.value;
        hueShift += adj.hue * 30 * w; // ±30° mapped from ±1
        satShift += adj.saturation * w;
        lumShift += adj.luminance * w;
      }

      if (hueShift == 0 && satShift == 0 && lumShift == 0) continue;

      var newHue = (hue + hueShift) % 360;
      if (newHue < 0) newHue += 360;
      final newSat = (sat + satShift * sat.clamp(0.1, 1.0)).clamp(0.0, 1.0);
      final newLum = (lum + lumShift * 0.5).clamp(0.0, 1.0);

      final rgb = _hslToRgb(newHue, newSat, newLum);
      pixel
        ..r = rgb[0]
        ..g = rgb[1]
        ..b = rgb[2];
    }

    return image;
  }

  /// Converts an sRGB colour to HSL.
  ///
  /// Returns [hue (0–360), saturation (0–1), luminance (0–1)].
  List<double> _rgbToHsl(int r, int g, int b) {
    final rf = r / 255;
    final gf = g / 255;
    final bf = b / 255;

    final maxC = math.max(rf, math.max(gf, bf));
    final minC = math.min(rf, math.min(gf, bf));
    final delta = maxC - minC;

    final lum = (maxC + minC) / 2;

    if (delta < 0.0001) return [0, 0, lum];

    final sat = lum > 0.5 ? delta / (2 - maxC - minC) : delta / (maxC + minC);

    double hue;
    if (maxC == rf) {
      hue = ((gf - bf) / delta) % 6;
    } else if (maxC == gf) {
      hue = (bf - rf) / delta + 2;
    } else {
      hue = (rf - gf) / delta + 4;
    }
    hue *= 60;
    if (hue < 0) hue += 360;

    return [hue, sat.clamp(0.0, 1.0), lum.clamp(0.0, 1.0)];
  }

  /// Converts HSL back to sRGB integers [r, g, b] in 0–255.
  List<int> _hslToRgb(double h, double s, double l) {
    if (s < 0.0001) {
      final grey = (l * 255).round().clamp(0, 255);
      return [grey, grey, grey];
    }

    final q = l < 0.5 ? l * (1 + s) : l + s - l * s;
    final p = 2 * l - q;
    final hNorm = h / 360;

    int channel(double t) {
      var tc = t;
      if (tc < 0) tc += 1;
      if (tc > 1) tc -= 1;
      double value;
      if (tc < 1 / 6) {
        value = p + (q - p) * 6 * tc;
      } else if (tc < 1 / 2) {
        value = q;
      } else if (tc < 2 / 3) {
        value = p + (q - p) * (2 / 3 - tc) * 6;
      } else {
        value = p;
      }
      return (value * 255).round().clamp(0, 255);
    }

    return [channel(hNorm + 1 / 3), channel(hNorm), channel(hNorm - 1 / 3)];
  }
}

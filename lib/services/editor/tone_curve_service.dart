import 'dart:typed_data';

import 'package:in_sreerajp_imgvidgal/models/editor/tone_curve.dart';

/// Turns the points the user dragged into the 256 entry table the renderer
/// reads.
///
/// A lookup table is used rather than maths per pixel because a photo has
/// millions of pixels but only 256 possible channel values. Building the
/// table once makes the whole tone stage a single array read per pixel.
class ToneCurveService {
  const ToneCurveService();

  /// The table for a curve that leaves the channel alone.
  static final Uint8List identityTable = _buildIdentity();

  static Uint8List _buildIdentity() {
    final table = Uint8List(256);
    for (var i = 0; i < 256; i++) {
      table[i] = i;
    }
    return table;
  }

  /// Cleans up [points] so the interpolation always has something usable.
  ///
  /// Points are sorted, values outside 0 to 255 are pulled back in, and two
  /// points sharing an input are collapsed. A curve with fewer than two
  /// usable points falls back to the straight line.
  List<CurvePoint> sanitize(List<CurvePoint> points) {
    final cleaned = <CurvePoint>[];
    for (final point in points) {
      if (point.input.isNaN || point.output.isNaN) continue;
      if (point.input.isInfinite || point.output.isInfinite) continue;
      cleaned.add(
        CurvePoint(
          point.input.clamp(0.0, 255.0),
          point.output.clamp(0.0, 255.0),
        ),
      );
    }

    cleaned.sort((a, b) => a.input.compareTo(b.input));

    final unique = <CurvePoint>[];
    for (final point in cleaned) {
      if (unique.isNotEmpty &&
          (unique.last.input - point.input).abs() < 0.0001) {
        // Two points on the same input would divide by zero; the later one
        // wins, which matches what dragging a handle onto another looks like.
        unique[unique.length - 1] = point;
        continue;
      }
      unique.add(point);
    }

    if (unique.length < 2) return ToneCurve.linear.points;
    return unique;
  }

  /// The output value for [input], reading straight from the curve.
  ///
  /// Values before the first point and after the last one are held flat, so
  /// a curve the user only shaped in the middle still covers the full range.
  double evaluate(List<CurvePoint> points, double input) {
    final sanitized = sanitize(points);
    final x = input.clamp(0.0, 255.0);

    if (x <= sanitized.first.input) return sanitized.first.output;
    if (x >= sanitized.last.input) return sanitized.last.output;

    for (var i = 0; i < sanitized.length - 1; i++) {
      final a = sanitized[i];
      final b = sanitized[i + 1];
      if (x >= a.input && x <= b.input) {
        final span = b.input - a.input;
        if (span.abs() < 0.0001) return b.output;
        final t = (x - a.input) / span;
        // Smoothstep instead of a straight line, so a dragged handle gives a
        // soft bend rather than a visible kink.
        final eased = t * t * (3 - 2 * t);
        return a.output + (b.output - a.output) * eased;
      }
    }

    return sanitized.last.output;
  }

  /// Builds the full 256 entry table for [curve].
  ///
  /// An untouched curve returns the shared identity table, so the common case
  /// allocates nothing.
  Uint8List buildTable(ToneCurve curve) {
    if (curve.isLinear) return identityTable;

    final sanitized = sanitize(curve.points);
    final table = Uint8List(256);
    for (var i = 0; i < 256; i++) {
      table[i] = evaluate(sanitized, i.toDouble()).round().clamp(0, 255);
    }
    return table;
  }

  /// Runs one table into another, so several curves become a single table.
  ///
  /// Used to fold the shared RGB curve into each channel's own curve, which
  /// keeps the renderer down to one lookup per channel.
  Uint8List compose(Uint8List first, Uint8List second) {
    final table = Uint8List(256);
    for (var i = 0; i < 256; i++) {
      table[i] = second[first[i]];
    }
    return table;
  }
}

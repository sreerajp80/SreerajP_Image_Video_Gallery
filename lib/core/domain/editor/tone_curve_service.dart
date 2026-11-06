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

  /// The output value for [input] using natural cubic spline interpolation.
  ///
  /// Values before the first point and after the last one are held flat, so
  /// a curve the user only shaped in the middle still covers the full range.
  double evaluate(List<CurvePoint> points, double input) {
    final sanitized = sanitize(points);
    final x = input.clamp(0.0, 255.0);
    final n = sanitized.length;

    if (x <= sanitized.first.input) return sanitized.first.output;
    if (x >= sanitized.last.input) return sanitized.last.output;
    if (n == 2) {
      // Two points: linear interpolation is exact.
      final a = sanitized[0];
      final b = sanitized[1];
      final span = b.input - a.input;
      if (span.abs() < 0.0001) return b.output;
      final t = (x - a.input) / span;
      return a.output + (b.output - a.output) * t;
    }

    final coeffs = _cubicSplineCoefficients(sanitized);
    return _evaluateSpline(sanitized, coeffs, x);
  }

  /// Computes second derivatives for natural cubic spline (zero second
  /// derivative at the two endpoints).
  ///
  /// Uses the tridiagonal algorithm, which is O(n) and stable for the
  /// monotonic inputs we have after sanitizing.
  List<double> _cubicSplineCoefficients(List<CurvePoint> points) {
    final n = points.length;
    final m2 = List<double>.filled(n, 0); // second derivatives

    if (n <= 2) return m2;

    // Forward sweep of the tridiagonal system.
    final h = List<double>.filled(n - 1, 0);
    for (var i = 0; i < n - 1; i++) {
      h[i] = points[i + 1].input - points[i].input;
    }

    final alpha = List<double>.filled(n, 0);
    for (var i = 1; i < n - 1; i++) {
      alpha[i] =
          3 / h[i] * (points[i + 1].output - points[i].output) -
          3 / h[i - 1] * (points[i].output - points[i - 1].output);
    }

    final l = List<double>.filled(n, 1);
    final mu = List<double>.filled(n, 0);
    final z = List<double>.filled(n, 0);

    for (var i = 1; i < n - 1; i++) {
      l[i] =
          2 * (points[i + 1].input - points[i - 1].input) -
          h[i - 1] * mu[i - 1];
      if (l[i].abs() < 1e-12) l[i] = 1e-12; // guard against division by zero
      mu[i] = h[i] / l[i];
      z[i] = (alpha[i] - h[i - 1] * z[i - 1]) / l[i];
    }

    // Back substitution.
    for (var j = n - 2; j > 0; j--) {
      m2[j] = z[j] - mu[j] * m2[j + 1];
    }

    return m2;
  }

  /// Evaluates the cubic spline at position [x], given precomputed second
  /// derivatives [m2].
  double _evaluateSpline(List<CurvePoint> points, List<double> m2, double x) {
    // Find the segment.
    var seg = 0;
    for (var i = 0; i < points.length - 1; i++) {
      if (x <= points[i + 1].input) {
        seg = i;
        break;
      }
    }

    final h = points[seg + 1].input - points[seg].input;
    if (h.abs() < 0.0001) return points[seg + 1].output;

    final a = (points[seg + 1].input - x) / h;
    final b = (x - points[seg].input) / h;

    final value =
        a * points[seg].output +
        b * points[seg + 1].output +
        ((a * a * a - a) * m2[seg] + (b * b * b - b) * m2[seg + 1]) *
            (h * h) /
            6;

    return value.clamp(0.0, 255.0);
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

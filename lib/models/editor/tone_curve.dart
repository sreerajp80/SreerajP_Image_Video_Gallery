import 'package:flutter/foundation.dart';

/// One point the user has dragged on a tone curve.
///
/// Both values are 0 to 255. [input] is the brightness a pixel has now,
/// [output] is what it becomes.
@immutable
class CurvePoint {
  final double input;
  final double output;

  const CurvePoint(this.input, this.output);

  CurvePoint copyWith({double? input, double? output}) =>
      CurvePoint(input ?? this.input, output ?? this.output);

  Map<String, dynamic> toMap() => <String, dynamic>{
    'input': input,
    'output': output,
  };

  factory CurvePoint.fromMap(Map<String, dynamic> map) => CurvePoint(
    (map['input'] as num?)?.toDouble() ?? 0,
    (map['output'] as num?)?.toDouble() ?? 0,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CurvePoint &&
          runtimeType == other.runtimeType &&
          input == other.input &&
          output == other.output;

  @override
  int get hashCode => Object.hash(input, output);

  @override
  String toString() => 'CurvePoint($input -> $output)';
}

/// A tone curve for one channel, held as its control points.
///
/// The straight line from (0,0) to (255,255) leaves the channel alone, and is
/// what [linear] gives. `ToneCurveService` turns the points into the 256 entry
/// lookup table the renderer uses.
@immutable
class ToneCurve {
  /// Control points, expected to be sorted by [CurvePoint.input].
  final List<CurvePoint> points;

  const ToneCurve(this.points);

  /// The identity curve: every value maps to itself.
  static const ToneCurve linear = ToneCurve(<CurvePoint>[
    CurvePoint(0, 0),
    CurvePoint(255, 255),
  ]);

  /// Whether this curve leaves the channel untouched.
  ///
  /// Two end points on the diagonal is the common case and is checked
  /// cheaply, so an untouched curve costs the renderer nothing.
  bool get isLinear {
    if (points.length != 2) return false;
    final first = points.first;
    final last = points.last;
    return first.input.abs() < 0.001 &&
        first.output.abs() < 0.001 &&
        (last.input - 255).abs() < 0.001 &&
        (last.output - 255).abs() < 0.001;
  }

  ToneCurve copyWith({List<CurvePoint>? points}) =>
      ToneCurve(points ?? this.points);

  /// Returns a copy with [point] added, keeping the list sorted by input.
  ToneCurve withPoint(CurvePoint point) {
    final next = <CurvePoint>[...points, point]
      ..sort((a, b) => a.input.compareTo(b.input));
    return ToneCurve(next);
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'points': points.map((p) => p.toMap()).toList(),
  };

  factory ToneCurve.fromMap(Map<String, dynamic> map) {
    final raw = map['points'];
    if (raw is! List || raw.isEmpty) return ToneCurve.linear;
    return ToneCurve(
      raw
          .whereType<Map>()
          .map((e) => CurvePoint.fromMap(Map<String, dynamic>.from(e)))
          .toList(growable: false),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ToneCurve &&
          runtimeType == other.runtimeType &&
          listEquals(points, other.points);

  @override
  int get hashCode => Object.hashAll(points);

  @override
  String toString() => 'ToneCurve(${points.length} points)';
}

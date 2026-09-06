import 'package:flutter/foundation.dart';

/// A point in fractions of the image, from 0 to 1 on each axis.
///
/// Normalised so a doodle drawn on the small preview lands in exactly the
/// same place on the full-resolution render.
@immutable
class NormalizedPoint {
  final double x;
  final double y;

  const NormalizedPoint(this.x, this.y);

  NormalizedPoint copyWith({double? x, double? y}) =>
      NormalizedPoint(x ?? this.x, y ?? this.y);

  Map<String, dynamic> toMap() => <String, dynamic>{'x': x, 'y': y};

  factory NormalizedPoint.fromMap(Map<String, dynamic> map) => NormalizedPoint(
    (map['x'] as num?)?.toDouble() ?? 0,
    (map['y'] as num?)?.toDouble() ?? 0,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NormalizedPoint &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'NormalizedPoint($x, $y)';
}

/// The geometric annotations the shape tool can draw.
enum ShapeKind {
  rectangle,
  ellipse,
  line,
  arrow;

  static ShapeKind fromName(String value) {
    return ShapeKind.values.firstWhere(
      (kind) => kind.name == value,
      orElse: () => ShapeKind.rectangle,
    );
  }
}

/// Anything the user drew or typed on top of the photo.
///
/// Layers are drawn in list order, so a later layer covers an earlier one.
/// Colours are plain ARGB integers rather than `Color` objects so a layer can
/// cross into the render isolate without any UI type coming with it.
@immutable
sealed class MarkupLayer {
  /// Identifier used to select, move, or delete this one layer.
  final String id;

  /// Line or text colour as a 32 bit ARGB value.
  final int colorArgb;

  /// How see-through the layer is, 0 to 1.
  final double opacity;

  const MarkupLayer({
    required this.id,
    required this.colorArgb,
    this.opacity = 1,
  });

  /// Discriminator written into the map, used to rebuild the right subclass.
  String get kind;

  Map<String, dynamic> toMap();

  /// Rebuilds any layer from its map, or null when the map is not a layer.
  ///
  /// Returning null instead of throwing keeps a single bad stored layer from
  /// taking down the whole edit session.
  static MarkupLayer? fromMap(Map<String, dynamic> map) {
    switch (map['kind'] as String? ?? '') {
      case 'doodle':
        return DoodleStroke.fromMap(map);
      case 'shape':
        return ShapeAnnotation.fromMap(map);
      case 'text':
        return TextAnnotation.fromMap(map);
      default:
        return null;
    }
  }
}

/// A freehand line, held as the points the finger passed through.
@immutable
class DoodleStroke extends MarkupLayer {
  /// Points along the stroke, in drawing order.
  final List<NormalizedPoint> points;

  /// Line thickness as a fraction of the image's shorter side.
  final double strokeWidth;

  const DoodleStroke({
    required super.id,
    required super.colorArgb,
    required this.points,
    this.strokeWidth = 0.01,
    super.opacity,
  });

  @override
  String get kind => 'doodle';

  DoodleStroke copyWith({
    String? id,
    int? colorArgb,
    List<NormalizedPoint>? points,
    double? strokeWidth,
    double? opacity,
  }) {
    return DoodleStroke(
      id: id ?? this.id,
      colorArgb: colorArgb ?? this.colorArgb,
      points: points ?? this.points,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      opacity: opacity ?? this.opacity,
    );
  }

  /// Returns a copy with [point] appended, used while the finger is moving.
  DoodleStroke withPoint(NormalizedPoint point) =>
      copyWith(points: <NormalizedPoint>[...points, point]);

  @override
  Map<String, dynamic> toMap() => <String, dynamic>{
    'kind': kind,
    'id': id,
    'colorArgb': colorArgb,
    'opacity': opacity,
    'strokeWidth': strokeWidth,
    'points': points.map((p) => p.toMap()).toList(),
  };

  factory DoodleStroke.fromMap(Map<String, dynamic> map) {
    final raw = map['points'];
    return DoodleStroke(
      id: map['id'] as String? ?? '',
      colorArgb: (map['colorArgb'] as num?)?.toInt() ?? 0xFFFFFFFF,
      opacity: (map['opacity'] as num?)?.toDouble() ?? 1,
      strokeWidth: (map['strokeWidth'] as num?)?.toDouble() ?? 0.01,
      points: raw is List
          ? raw
                .whereType<Map>()
                .map(
                  (e) => NormalizedPoint.fromMap(Map<String, dynamic>.from(e)),
                )
                .toList(growable: false)
          : const <NormalizedPoint>[],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DoodleStroke &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          colorArgb == other.colorArgb &&
          opacity == other.opacity &&
          strokeWidth == other.strokeWidth &&
          listEquals(points, other.points);

  @override
  int get hashCode =>
      Object.hash(id, colorArgb, opacity, strokeWidth, Object.hashAll(points));

  @override
  String toString() => 'DoodleStroke($id, ${points.length} points)';
}

/// A rectangle, ellipse, line, or arrow between two dragged corners.
@immutable
class ShapeAnnotation extends MarkupLayer {
  final ShapeKind shape;

  /// Where the drag started.
  final NormalizedPoint start;

  /// Where the drag ended.
  final NormalizedPoint end;

  /// Outline thickness as a fraction of the image's shorter side.
  final double strokeWidth;

  /// Whether the inside is painted with [colorArgb] as well as the outline.
  final bool filled;

  const ShapeAnnotation({
    required super.id,
    required super.colorArgb,
    required this.shape,
    required this.start,
    required this.end,
    this.strokeWidth = 0.01,
    this.filled = false,
    super.opacity,
  });

  @override
  String get kind => 'shape';

  ShapeAnnotation copyWith({
    String? id,
    int? colorArgb,
    ShapeKind? shape,
    NormalizedPoint? start,
    NormalizedPoint? end,
    double? strokeWidth,
    bool? filled,
    double? opacity,
  }) {
    return ShapeAnnotation(
      id: id ?? this.id,
      colorArgb: colorArgb ?? this.colorArgb,
      shape: shape ?? this.shape,
      start: start ?? this.start,
      end: end ?? this.end,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      filled: filled ?? this.filled,
      opacity: opacity ?? this.opacity,
    );
  }

  @override
  Map<String, dynamic> toMap() => <String, dynamic>{
    'kind': kind,
    'id': id,
    'colorArgb': colorArgb,
    'opacity': opacity,
    'shape': shape.name,
    'start': start.toMap(),
    'end': end.toMap(),
    'strokeWidth': strokeWidth,
    'filled': filled,
  };

  factory ShapeAnnotation.fromMap(Map<String, dynamic> map) {
    NormalizedPoint readPoint(String key) {
      final raw = map[key];
      if (raw is Map) {
        return NormalizedPoint.fromMap(Map<String, dynamic>.from(raw));
      }
      return const NormalizedPoint(0, 0);
    }

    return ShapeAnnotation(
      id: map['id'] as String? ?? '',
      colorArgb: (map['colorArgb'] as num?)?.toInt() ?? 0xFFFFFFFF,
      opacity: (map['opacity'] as num?)?.toDouble() ?? 1,
      shape: ShapeKind.fromName(map['shape'] as String? ?? ''),
      start: readPoint('start'),
      end: readPoint('end'),
      strokeWidth: (map['strokeWidth'] as num?)?.toDouble() ?? 0.01,
      filled: map['filled'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShapeAnnotation &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          colorArgb == other.colorArgb &&
          opacity == other.opacity &&
          shape == other.shape &&
          start == other.start &&
          end == other.end &&
          strokeWidth == other.strokeWidth &&
          filled == other.filled;

  @override
  int get hashCode => Object.hash(
    id,
    colorArgb,
    opacity,
    shape,
    start,
    end,
    strokeWidth,
    filled,
  );

  @override
  String toString() => 'ShapeAnnotation($id, ${shape.name})';
}

/// A short line of text placed on the photo.
@immutable
class TextAnnotation extends MarkupLayer {
  /// The text itself. It is user content, so it is never logged.
  final String text;

  /// Top-left corner of the text box.
  final NormalizedPoint position;

  /// Font height as a fraction of the image's shorter side.
  final double fontScale;

  /// Whether a contrasting plate is drawn behind the text so it stays
  /// readable over a busy photo.
  final bool hasBackground;

  /// Background plate colour as ARGB, used only when [hasBackground] is true.
  final int backgroundArgb;

  const TextAnnotation({
    required super.id,
    required super.colorArgb,
    required this.text,
    required this.position,
    this.fontScale = 0.06,
    this.hasBackground = false,
    this.backgroundArgb = 0x99000000,
    super.opacity,
  });

  @override
  String get kind => 'text';

  TextAnnotation copyWith({
    String? id,
    int? colorArgb,
    String? text,
    NormalizedPoint? position,
    double? fontScale,
    bool? hasBackground,
    int? backgroundArgb,
    double? opacity,
  }) {
    return TextAnnotation(
      id: id ?? this.id,
      colorArgb: colorArgb ?? this.colorArgb,
      text: text ?? this.text,
      position: position ?? this.position,
      fontScale: fontScale ?? this.fontScale,
      hasBackground: hasBackground ?? this.hasBackground,
      backgroundArgb: backgroundArgb ?? this.backgroundArgb,
      opacity: opacity ?? this.opacity,
    );
  }

  @override
  Map<String, dynamic> toMap() => <String, dynamic>{
    'kind': kind,
    'id': id,
    'colorArgb': colorArgb,
    'opacity': opacity,
    'text': text,
    'position': position.toMap(),
    'fontScale': fontScale,
    'hasBackground': hasBackground,
    'backgroundArgb': backgroundArgb,
  };

  factory TextAnnotation.fromMap(Map<String, dynamic> map) {
    final raw = map['position'];
    return TextAnnotation(
      id: map['id'] as String? ?? '',
      colorArgb: (map['colorArgb'] as num?)?.toInt() ?? 0xFFFFFFFF,
      opacity: (map['opacity'] as num?)?.toDouble() ?? 1,
      text: map['text'] as String? ?? '',
      position: raw is Map
          ? NormalizedPoint.fromMap(Map<String, dynamic>.from(raw))
          : const NormalizedPoint(0, 0),
      fontScale: (map['fontScale'] as num?)?.toDouble() ?? 0.06,
      hasBackground: map['hasBackground'] as bool? ?? false,
      backgroundArgb: (map['backgroundArgb'] as num?)?.toInt() ?? 0x99000000,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextAnnotation &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          colorArgb == other.colorArgb &&
          opacity == other.opacity &&
          text == other.text &&
          position == other.position &&
          fontScale == other.fontScale &&
          hasBackground == other.hasBackground &&
          backgroundArgb == other.backgroundArgb;

  @override
  int get hashCode => Object.hash(
    id,
    colorArgb,
    opacity,
    text,
    position,
    fontScale,
    hasBackground,
    backgroundArgb,
  );

  // The text itself is user content, so only its length is described here.
  @override
  String toString() => 'TextAnnotation($id, ${text.length} chars)';
}

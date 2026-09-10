import 'package:flutter/foundation.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/markup_layer.dart';

/// The two mask shapes the selective tool supports.
enum MaskShape {
  /// A linear gradient between two points.
  linear,

  /// A circular region defined by a centre and a radius point.
  radial;

  static MaskShape fromName(String value) {
    return MaskShape.values.firstWhere(
      (shape) => shape.name == value,
      orElse: () => MaskShape.linear,
    );
  }
}

/// One selective mask with its own local adjustments.
///
/// The mask defines a region of the image (linear gradient or radial circle)
/// and carries its own set of exposure, contrast, temperature, and blur
/// values that are blended into the pixels by the mask weight.
@immutable
class SelectiveMask {
  /// Unique identifier for this mask.
  final String id;

  /// Whether this is a linear gradient or a radial circle.
  final MaskShape shape;

  /// For linear: the start of the gradient. For radial: the centre.
  final NormalizedPoint startPoint;

  /// For linear: the end of the gradient. For radial: a point on the edge.
  final NormalizedPoint endPoint;

  /// How soft the mask edge is, 0 (hard) to 1 (very soft).
  final double feather;

  /// Whether the affected side is flipped.
  final bool invert;

  /// Local exposure adjustment, -1 to 1.
  final double exposure;

  /// Local contrast adjustment, -1 to 1.
  final double contrast;

  /// Local temperature shift, -1 to 1.
  final double temperature;

  /// Local blur strength, 0 to 1.
  final double blur;

  const SelectiveMask({
    required this.id,
    this.shape = MaskShape.linear,
    this.startPoint = const NormalizedPoint(0.5, 0.3),
    this.endPoint = const NormalizedPoint(0.5, 0.7),
    this.feather = 0.3,
    this.invert = false,
    this.exposure = 0,
    this.contrast = 0,
    this.temperature = 0,
    this.blur = 0,
  });

  /// Whether every adjustment slider is still at zero.
  bool get isNeutral =>
      exposure == 0 && contrast == 0 && temperature == 0 && blur == 0;

  SelectiveMask copyWith({
    String? id,
    MaskShape? shape,
    NormalizedPoint? startPoint,
    NormalizedPoint? endPoint,
    double? feather,
    bool? invert,
    double? exposure,
    double? contrast,
    double? temperature,
    double? blur,
  }) {
    return SelectiveMask(
      id: id ?? this.id,
      shape: shape ?? this.shape,
      startPoint: startPoint ?? this.startPoint,
      endPoint: endPoint ?? this.endPoint,
      feather: feather ?? this.feather,
      invert: invert ?? this.invert,
      exposure: exposure ?? this.exposure,
      contrast: contrast ?? this.contrast,
      temperature: temperature ?? this.temperature,
      blur: blur ?? this.blur,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'shape': shape.name,
    'startPoint': startPoint.toMap(),
    'endPoint': endPoint.toMap(),
    'feather': feather,
    'invert': invert,
    'exposure': exposure,
    'contrast': contrast,
    'temperature': temperature,
    'blur': blur,
  };

  factory SelectiveMask.fromMap(Map<String, dynamic> map) {
    NormalizedPoint readPoint(String key) {
      final raw = map[key];
      if (raw is Map) {
        return NormalizedPoint.fromMap(Map<String, dynamic>.from(raw));
      }
      return const NormalizedPoint(0.5, 0.5);
    }

    return SelectiveMask(
      id: map['id'] as String? ?? '',
      shape: MaskShape.fromName(map['shape'] as String? ?? ''),
      startPoint: readPoint('startPoint'),
      endPoint: readPoint('endPoint'),
      feather: (map['feather'] as num?)?.toDouble() ?? 0.3,
      invert: map['invert'] as bool? ?? false,
      exposure: (map['exposure'] as num?)?.toDouble() ?? 0,
      contrast: (map['contrast'] as num?)?.toDouble() ?? 0,
      temperature: (map['temperature'] as num?)?.toDouble() ?? 0,
      blur: (map['blur'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectiveMask &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          shape == other.shape &&
          startPoint == other.startPoint &&
          endPoint == other.endPoint &&
          feather == other.feather &&
          invert == other.invert &&
          exposure == other.exposure &&
          contrast == other.contrast &&
          temperature == other.temperature &&
          blur == other.blur;

  @override
  int get hashCode => Object.hash(
    id,
    shape,
    startPoint,
    endPoint,
    feather,
    invert,
    exposure,
    contrast,
    temperature,
    blur,
  );

  @override
  String toString() => 'SelectiveMask($id, $shape, neutral: $isNeutral)';
}

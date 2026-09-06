import 'package:flutter/foundation.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/crop_transform.dart';

/// How a redacted area is hidden.
enum RedactionMode {
  /// Softens the area so it cannot be read.
  blur,

  /// Replaces the area with large blocks of averaged colour.
  pixelate,

  /// Paints the area a solid colour.
  blackout;

  static RedactionMode fromName(String value) {
    return RedactionMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => RedactionMode.blur,
    );
  }
}

/// One area of the photo the user wants hidden.
///
/// Redaction replaces the real pixels rather than laying something over
/// them, so in the saved copy the hidden detail is genuinely gone and cannot
/// be peeled back off. The area is given in the coordinates of the image as
/// the editor is showing it, that is after any crop or rotation.
@immutable
class RedactionRegion {
  /// Identifier used to select or delete this one region.
  final String id;

  /// The hidden area, in fractions of the image.
  final NormalizedRect rect;

  final RedactionMode mode;

  /// How strong the effect is, 0 to 1.
  ///
  /// It sets the blur radius or the block size. It is ignored for
  /// [RedactionMode.blackout], which is always fully opaque.
  final double strength;

  /// Fill colour for [RedactionMode.blackout], as a 32 bit ARGB value.
  final int colorArgb;

  const RedactionRegion({
    required this.id,
    required this.rect,
    this.mode = RedactionMode.blur,
    this.strength = 0.5,
    this.colorArgb = 0xFF000000,
  });

  RedactionRegion copyWith({
    String? id,
    NormalizedRect? rect,
    RedactionMode? mode,
    double? strength,
    int? colorArgb,
  }) {
    return RedactionRegion(
      id: id ?? this.id,
      rect: rect ?? this.rect,
      mode: mode ?? this.mode,
      strength: strength ?? this.strength,
      colorArgb: colorArgb ?? this.colorArgb,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'rect': rect.toMap(),
    'mode': mode.name,
    'strength': strength,
    'colorArgb': colorArgb,
  };

  factory RedactionRegion.fromMap(Map<String, dynamic> map) {
    final raw = map['rect'];
    return RedactionRegion(
      id: map['id'] as String? ?? '',
      rect: raw is Map
          ? NormalizedRect.fromMap(Map<String, dynamic>.from(raw))
          : NormalizedRect.full,
      mode: RedactionMode.fromName(map['mode'] as String? ?? ''),
      strength: (map['strength'] as num?)?.toDouble() ?? 0.5,
      colorArgb: (map['colorArgb'] as num?)?.toInt() ?? 0xFF000000,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RedactionRegion &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          rect == other.rect &&
          mode == other.mode &&
          strength == other.strength &&
          colorArgb == other.colorArgb;

  @override
  int get hashCode => Object.hash(id, rect, mode, strength, colorArgb);

  @override
  String toString() => 'RedactionRegion($id, ${mode.name})';
}

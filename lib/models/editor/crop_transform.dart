import 'package:flutter/foundation.dart';

/// Fixed shapes the crop box can be locked to.
///
/// [free] lets the user drag any shape. [original] keeps the shape of the
/// photo being edited, so its value depends on the image and is resolved by
/// `CropTransformService`.
enum CropAspectPreset {
  free,
  original,
  square,
  ratio4x3,
  ratio3x4,
  ratio16x9,
  ratio9x16,
  ratio3x2,
  ratio2x3;

  /// Width divided by height, or null when the shape is not fixed here.
  ///
  /// [free] has no ratio at all, and [original] only gets one once the image
  /// size is known.
  double? get ratio {
    switch (this) {
      case CropAspectPreset.free:
      case CropAspectPreset.original:
        return null;
      case CropAspectPreset.square:
        return 1;
      case CropAspectPreset.ratio4x3:
        return 4 / 3;
      case CropAspectPreset.ratio3x4:
        return 3 / 4;
      case CropAspectPreset.ratio16x9:
        return 16 / 9;
      case CropAspectPreset.ratio9x16:
        return 9 / 16;
      case CropAspectPreset.ratio3x2:
        return 3 / 2;
      case CropAspectPreset.ratio2x3:
        return 2 / 3;
    }
  }

  /// Reads a preset name back, falling back to [free] on anything unknown.
  static CropAspectPreset fromName(String value) {
    return CropAspectPreset.values.firstWhere(
      (preset) => preset.name == value,
      orElse: () => CropAspectPreset.free,
    );
  }
}

/// A rectangle expressed in fractions of the image, from 0 to 1.
///
/// Normalised coordinates keep the crop independent of the pixel size, so the
/// same box works for the small preview and the full-resolution render.
@immutable
class NormalizedRect {
  final double left;
  final double top;
  final double right;
  final double bottom;

  const NormalizedRect({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  /// The whole image.
  static const NormalizedRect full = NormalizedRect(
    left: 0,
    top: 0,
    right: 1,
    bottom: 1,
  );

  double get width => right - left;
  double get height => bottom - top;

  /// Whether this rectangle covers the entire image.
  bool get isFull =>
      left <= 0.0001 && top <= 0.0001 && right >= 0.9999 && bottom >= 0.9999;

  /// Whether the rectangle has a real, positive area inside the image.
  bool get isValid =>
      left >= 0 &&
      top >= 0 &&
      right <= 1 &&
      bottom <= 1 &&
      width > 0 &&
      height > 0;

  NormalizedRect copyWith({
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    return NormalizedRect(
      left: left ?? this.left,
      top: top ?? this.top,
      right: right ?? this.right,
      bottom: bottom ?? this.bottom,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'left': left,
    'top': top,
    'right': right,
    'bottom': bottom,
  };

  factory NormalizedRect.fromMap(Map<String, dynamic> map) {
    return NormalizedRect(
      left: (map['left'] as num?)?.toDouble() ?? 0,
      top: (map['top'] as num?)?.toDouble() ?? 0,
      right: (map['right'] as num?)?.toDouble() ?? 1,
      bottom: (map['bottom'] as num?)?.toDouble() ?? 1,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NormalizedRect &&
          runtimeType == other.runtimeType &&
          left == other.left &&
          top == other.top &&
          right == other.right &&
          bottom == other.bottom;

  @override
  int get hashCode => Object.hash(left, top, right, bottom);

  @override
  String toString() => 'NormalizedRect($left, $top, $right, $bottom)';
}

/// How far each corner is pulled in to correct perspective.
///
/// Every value is a fraction of the image width or height. Positive numbers
/// pull the corner inward. All zeros means no correction, which lets the
/// pipeline skip the (expensive) warp entirely.
@immutable
class PerspectiveSkew {
  /// Horizontal pull of the top edge. Positive narrows the top.
  final double topInset;

  /// Horizontal pull of the bottom edge. Positive narrows the bottom.
  final double bottomInset;

  /// Vertical pull of the left edge. Positive shortens the left side.
  final double leftInset;

  /// Vertical pull of the right edge. Positive shortens the right side.
  final double rightInset;

  const PerspectiveSkew({
    this.topInset = 0,
    this.bottomInset = 0,
    this.leftInset = 0,
    this.rightInset = 0,
  });

  /// No correction at all.
  static const PerspectiveSkew none = PerspectiveSkew();

  /// Whether every inset is effectively zero.
  bool get isIdentity =>
      topInset.abs() < 0.0001 &&
      bottomInset.abs() < 0.0001 &&
      leftInset.abs() < 0.0001 &&
      rightInset.abs() < 0.0001;

  PerspectiveSkew copyWith({
    double? topInset,
    double? bottomInset,
    double? leftInset,
    double? rightInset,
  }) {
    return PerspectiveSkew(
      topInset: topInset ?? this.topInset,
      bottomInset: bottomInset ?? this.bottomInset,
      leftInset: leftInset ?? this.leftInset,
      rightInset: rightInset ?? this.rightInset,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'topInset': topInset,
    'bottomInset': bottomInset,
    'leftInset': leftInset,
    'rightInset': rightInset,
  };

  factory PerspectiveSkew.fromMap(Map<String, dynamic> map) {
    return PerspectiveSkew(
      topInset: (map['topInset'] as num?)?.toDouble() ?? 0,
      bottomInset: (map['bottomInset'] as num?)?.toDouble() ?? 0,
      leftInset: (map['leftInset'] as num?)?.toDouble() ?? 0,
      rightInset: (map['rightInset'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PerspectiveSkew &&
          runtimeType == other.runtimeType &&
          topInset == other.topInset &&
          bottomInset == other.bottomInset &&
          leftInset == other.leftInset &&
          rightInset == other.rightInset;

  @override
  int get hashCode => Object.hash(topInset, bottomInset, leftInset, rightInset);

  @override
  String toString() =>
      'PerspectiveSkew(top: $topInset, bottom: $bottomInset, '
      'left: $leftInset, right: $rightInset)';
}

/// Every geometry change the editor can apply, as one immutable value.
///
/// The order the render pipeline uses is fixed: perspective, then straighten,
/// then quarter turns and flips, then the crop box. Keeping the order in one
/// place means the small preview and the full render always agree.
@immutable
class CropTransform {
  /// The kept part of the image, in fractions of its size.
  final NormalizedRect rect;

  /// Shape the crop box is locked to.
  final CropAspectPreset aspectPreset;

  /// Number of 90 degree clockwise turns, always 0 to 3.
  final int quarterTurns;

  /// Fine levelling angle in degrees, negative tilts anticlockwise.
  final double straightenDegrees;

  /// Whether the image is mirrored left to right.
  final bool flipHorizontal;

  /// Whether the image is mirrored top to bottom.
  final bool flipVertical;

  /// Corner pulls that square up a photo taken at an angle.
  final PerspectiveSkew perspective;

  const CropTransform({
    this.rect = NormalizedRect.full,
    this.aspectPreset = CropAspectPreset.free,
    this.quarterTurns = 0,
    this.straightenDegrees = 0,
    this.flipHorizontal = false,
    this.flipVertical = false,
    this.perspective = PerspectiveSkew.none,
  });

  /// An untouched image.
  static const CropTransform identity = CropTransform();

  /// Whether this transform would change the image at all.
  bool get isIdentity =>
      rect.isFull &&
      quarterTurns == 0 &&
      straightenDegrees.abs() < 0.0001 &&
      !flipHorizontal &&
      !flipVertical &&
      perspective.isIdentity;

  CropTransform copyWith({
    NormalizedRect? rect,
    CropAspectPreset? aspectPreset,
    int? quarterTurns,
    double? straightenDegrees,
    bool? flipHorizontal,
    bool? flipVertical,
    PerspectiveSkew? perspective,
  }) {
    return CropTransform(
      rect: rect ?? this.rect,
      aspectPreset: aspectPreset ?? this.aspectPreset,
      quarterTurns: quarterTurns ?? this.quarterTurns,
      straightenDegrees: straightenDegrees ?? this.straightenDegrees,
      flipHorizontal: flipHorizontal ?? this.flipHorizontal,
      flipVertical: flipVertical ?? this.flipVertical,
      perspective: perspective ?? this.perspective,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'rect': rect.toMap(),
    'aspectPreset': aspectPreset.name,
    'quarterTurns': quarterTurns,
    'straightenDegrees': straightenDegrees,
    'flipHorizontal': flipHorizontal,
    'flipVertical': flipVertical,
    'perspective': perspective.toMap(),
  };

  factory CropTransform.fromMap(Map<String, dynamic> map) {
    return CropTransform(
      rect: map['rect'] is Map
          ? NormalizedRect.fromMap(
              Map<String, dynamic>.from(map['rect'] as Map),
            )
          : NormalizedRect.full,
      aspectPreset: CropAspectPreset.fromName(
        map['aspectPreset'] as String? ?? '',
      ),
      quarterTurns: (map['quarterTurns'] as num?)?.toInt() ?? 0,
      straightenDegrees: (map['straightenDegrees'] as num?)?.toDouble() ?? 0,
      flipHorizontal: map['flipHorizontal'] as bool? ?? false,
      flipVertical: map['flipVertical'] as bool? ?? false,
      perspective: map['perspective'] is Map
          ? PerspectiveSkew.fromMap(
              Map<String, dynamic>.from(map['perspective'] as Map),
            )
          : PerspectiveSkew.none,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CropTransform &&
          runtimeType == other.runtimeType &&
          rect == other.rect &&
          aspectPreset == other.aspectPreset &&
          quarterTurns == other.quarterTurns &&
          straightenDegrees == other.straightenDegrees &&
          flipHorizontal == other.flipHorizontal &&
          flipVertical == other.flipVertical &&
          perspective == other.perspective;

  @override
  int get hashCode => Object.hash(
    rect,
    aspectPreset,
    quarterTurns,
    straightenDegrees,
    flipHorizontal,
    flipVertical,
    perspective,
  );

  @override
  String toString() =>
      'CropTransform(rect: $rect, preset: ${aspectPreset.name}, '
      'turns: $quarterTurns, straighten: $straightenDegrees)';
}

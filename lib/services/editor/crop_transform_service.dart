import 'dart:math' as math;

import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/crop_transform.dart';

/// The size of an image in whole pixels.
class PixelSize {
  final int width;
  final int height;

  const PixelSize(this.width, this.height);

  double get aspectRatio => height == 0 ? 1 : width / height;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PixelSize &&
          runtimeType == other.runtimeType &&
          width == other.width &&
          height == other.height;

  @override
  int get hashCode => Object.hash(width, height);

  @override
  String toString() => 'PixelSize(${width}x$height)';
}

/// A crop rectangle in whole pixels, ready for the `image` package.
class PixelRect {
  final int left;
  final int top;
  final int width;
  final int height;

  const PixelRect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  int get right => left + width;
  int get bottom => top + height;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PixelRect &&
          runtimeType == other.runtimeType &&
          left == other.left &&
          top == other.top &&
          width == other.width &&
          height == other.height;

  @override
  int get hashCode => Object.hash(left, top, width, height);

  @override
  String toString() => 'PixelRect($left, $top, ${width}x$height)';
}

/// All the crop, rotate, straighten, and perspective maths, as pure functions.
///
/// Nothing here decodes an image or touches a file. That keeps the geometry
/// fully unit tested on any machine, and means the small preview and the full
/// render can share exactly the same rules.
class CropTransformService {
  const CropTransformService();

  /// The ratio [preset] means for an image of [imageSize].
  ///
  /// [CropAspectPreset.original] only has a ratio once the image is known,
  /// and [CropAspectPreset.free] never has one.
  double? ratioFor(CropAspectPreset preset, PixelSize imageSize) {
    if (preset == CropAspectPreset.original) {
      if (imageSize.width <= 0 || imageSize.height <= 0) return null;
      return imageSize.width / imageSize.height;
    }
    return preset.ratio;
  }

  /// Keeps [rect] inside the image and no smaller than the allowed minimum.
  ///
  /// A crop box dragged past an edge or collapsed to nothing is a normal
  /// gesture result, so it is corrected here rather than rejected.
  NormalizedRect clampRect(NormalizedRect rect) {
    const minSize = AppConstants.editorMinCropFraction;

    var left = _clamp01(rect.left);
    var top = _clamp01(rect.top);
    var right = _clamp01(rect.right);
    var bottom = _clamp01(rect.bottom);

    // A dragged handle can cross over the opposite edge; swap rather than
    // producing a negative size.
    if (right < left) {
      final swap = left;
      left = right;
      right = swap;
    }
    if (bottom < top) {
      final swap = top;
      top = bottom;
      bottom = swap;
    }

    if (right - left < minSize) {
      if (left + minSize <= 1) {
        right = left + minSize;
      } else {
        left = 1 - minSize;
        right = 1;
      }
    }
    if (bottom - top < minSize) {
      if (top + minSize <= 1) {
        bottom = top + minSize;
      } else {
        top = 1 - minSize;
        bottom = 1;
      }
    }

    return NormalizedRect(left: left, top: top, right: right, bottom: bottom);
  }

  /// Reshapes [rect] to [ratio] while keeping its centre where it is.
  ///
  /// The box is shrunk rather than grown, so applying an aspect preset never
  /// pushes the crop outside the photo.
  NormalizedRect applyAspectRatio(
    NormalizedRect rect,
    double? ratio,
    PixelSize imageSize,
  ) {
    if (ratio == null || ratio <= 0) return clampRect(rect);
    if (imageSize.width <= 0 || imageSize.height <= 0) return clampRect(rect);

    final centerX = (rect.left + rect.right) / 2;
    final centerY = (rect.top + rect.bottom) / 2;

    // The ratio is about real pixels, so convert it into fractions of an
    // image that is not itself square.
    final imageRatio = imageSize.width / imageSize.height;
    final normalizedRatio = ratio / imageRatio;

    var width = rect.width;
    var height = width / normalizedRatio;
    if (height > rect.height) {
      height = rect.height;
      width = height * normalizedRatio;
    }

    // Never let the shaped box spill outside the image.
    if (width > 1) {
      width = 1;
      height = width / normalizedRatio;
    }
    if (height > 1) {
      height = 1;
      width = height * normalizedRatio;
    }

    var left = centerX - width / 2;
    var top = centerY - height / 2;
    left = left.clamp(0.0, 1 - width);
    top = top.clamp(0.0, 1 - height);

    return NormalizedRect(
      left: left,
      top: top,
      right: left + width,
      bottom: top + height,
    );
  }

  /// Turns a normalised crop into whole pixels for an image of [imageSize].
  ///
  /// The result is always at least one pixel wide and tall and always inside
  /// the image, because the `image` package throws on anything else.
  PixelRect toPixelRect(NormalizedRect rect, PixelSize imageSize) {
    final safe = clampRect(rect);
    final left = (safe.left * imageSize.width)
        .round()
        .clamp(0, math.max(0, imageSize.width - 1))
        .toInt();
    final top = (safe.top * imageSize.height)
        .round()
        .clamp(0, math.max(0, imageSize.height - 1))
        .toInt();
    final right = (safe.right * imageSize.width)
        .round()
        .clamp(left + 1, imageSize.width)
        .toInt();
    final bottom = (safe.bottom * imageSize.height)
        .round()
        .clamp(top + 1, imageSize.height)
        .toInt();

    return PixelRect(
      left: left,
      top: top,
      width: right - left,
      height: bottom - top,
    );
  }

  /// Keeps a straighten angle inside the slider's range.
  double clampStraighten(double degrees) {
    if (degrees.isNaN || degrees.isInfinite) return 0;
    const limit = AppConstants.editorStraightenMaxDegrees;
    return degrees.clamp(-limit, limit);
  }

  /// Normalises a quarter turn count to 0, 1, 2, or 3.
  ///
  /// Rotating right four times, or left once from zero, both have to land on
  /// a value the renderer understands.
  int normalizeQuarterTurns(int turns) {
    final wrapped = turns % 4;
    return wrapped < 0 ? wrapped + 4 : wrapped;
  }

  /// The size an image becomes after [turns] quarter turns.
  PixelSize sizeAfterQuarterTurns(PixelSize size, int turns) {
    final normalized = normalizeQuarterTurns(turns);
    if (normalized == 1 || normalized == 3) {
      return PixelSize(size.height, size.width);
    }
    return size;
  }

  /// The bounding box an image of [size] needs after tilting by [degrees].
  ///
  /// Rotating a rectangle makes it need a bigger box. The renderer uses this
  /// to work out how much of the tilted image to crop back off so the saved
  /// photo has no empty corners.
  PixelSize boundsAfterRotation(PixelSize size, double degrees) {
    final radians = clampStraighten(degrees) * math.pi / 180;
    final cos = math.cos(radians).abs();
    final sin = math.sin(radians).abs();
    final width = (size.width * cos + size.height * sin).ceil();
    final height = (size.width * sin + size.height * cos).ceil();
    return PixelSize(math.max(1, width), math.max(1, height));
  }

  /// The largest upright rectangle that fits inside a tilted image.
  ///
  /// This is what lets the straighten slider avoid blank triangles at the
  /// corners: the tilted photo is cropped back to this box.
  PixelRect largestInnerRect(PixelSize size, double degrees) {
    final angle = clampStraighten(degrees).abs() * math.pi / 180;
    if (angle < 0.0001) {
      return PixelRect(left: 0, top: 0, width: size.width, height: size.height);
    }

    final width = size.width.toDouble();
    final height = size.height.toDouble();
    final shorter = math.min(width, height);
    final longer = math.max(width, height);

    final sin = math.sin(angle);
    final cos = math.cos(angle);

    double innerWidth;
    double innerHeight;

    if (shorter <= 2 * sin * cos * longer || (sin - cos).abs() < 1e-10) {
      // Half-height / half-width case: the solution is a simple split.
      final half = 0.5 * shorter;
      if (width >= height) {
        innerWidth = half / sin;
        innerHeight = half / cos;
      } else {
        innerWidth = half / cos;
        innerHeight = half / sin;
      }
    } else {
      final denominator = cos * cos - sin * sin;
      innerWidth = (width * cos - height * sin) / denominator;
      innerHeight = (height * cos - width * sin) / denominator;
    }

    final safeWidth = innerWidth.floor().clamp(1, size.width).toInt();
    final safeHeight = innerHeight.floor().clamp(1, size.height).toInt();

    // The rotated image keeps the same centre, so the inner box is centred.
    final rotatedBounds = boundsAfterRotation(size, degrees);
    final left = ((rotatedBounds.width - safeWidth) / 2)
        .round()
        .clamp(0, math.max(0, rotatedBounds.width - 1))
        .toInt();
    final top = ((rotatedBounds.height - safeHeight) / 2)
        .round()
        .clamp(0, math.max(0, rotatedBounds.height - 1))
        .toInt();

    return PixelRect(
      left: left,
      top: top,
      width: math.min(safeWidth, rotatedBounds.width - left),
      height: math.min(safeHeight, rotatedBounds.height - top),
    );
  }

  /// Keeps every perspective inset inside the supported range.
  PerspectiveSkew clampPerspective(PerspectiveSkew skew) {
    const limit = AppConstants.editorPerspectiveMaxInset;

    double safe(double value) {
      if (value.isNaN || value.isInfinite) return 0;
      return value.clamp(-limit, limit);
    }

    return PerspectiveSkew(
      topInset: safe(skew.topInset),
      bottomInset: safe(skew.bottomInset),
      leftInset: safe(skew.leftInset),
      rightInset: safe(skew.rightInset),
    );
  }

  /// The four source corners a perspective warp reads from.
  ///
  /// The list is top-left, top-right, bottom-right, bottom-left, each in
  /// pixels. The renderer samples the photo at these corners and stretches
  /// them out to the full rectangle, which squares up a photo taken at an
  /// angle.
  List<List<double>> perspectiveCorners(PerspectiveSkew skew, PixelSize size) {
    final safe = clampPerspective(skew);
    final width = size.width.toDouble();
    final height = size.height.toDouble();

    final top = safe.topInset * width;
    final bottom = safe.bottomInset * width;
    final left = safe.leftInset * height;
    final right = safe.rightInset * height;

    return <List<double>>[
      <double>[top, left],
      <double>[width - top, right],
      <double>[width - bottom, height - right],
      <double>[bottom, height - left],
    ];
  }

  /// Whether [transform] would leave the image exactly as it was.
  ///
  /// The pipeline uses this to skip decoding work entirely when the user only
  /// touched, say, the watermark.
  bool isIdentity(CropTransform transform) => transform.isIdentity;

  double _clamp01(double value) {
    if (value.isNaN) return 0;
    return value.clamp(0.0, 1.0);
  }
}

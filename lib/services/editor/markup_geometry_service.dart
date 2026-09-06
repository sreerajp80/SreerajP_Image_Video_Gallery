import 'dart:math' as math;

import 'package:in_sreerajp_imgvidgal/models/editor/crop_transform.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/markup_layer.dart';
import 'package:in_sreerajp_imgvidgal/services/editor/crop_transform_service.dart';

/// A point in whole pixels.
class PixelPoint {
  final int x;
  final int y;

  const PixelPoint(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PixelPoint &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'PixelPoint($x, $y)';
}

/// The maths behind the markup canvas, with no drawing in it.
///
/// The canvas widget captures fingers in its own coordinates, and the
/// renderer draws in image pixels. Both sides go through these functions, so
/// a doodle drawn on a small preview lands in the same place on the saved
/// full-resolution copy.
class MarkupGeometryService {
  const MarkupGeometryService();

  /// Turns a normalised point into pixels for an image of [size].
  ///
  /// The result is always inside the image, because a finger can slip past
  /// the edge of the canvas mid-stroke.
  PixelPoint toPixel(NormalizedPoint point, PixelSize size) {
    final x = (point.x * size.width).round().clamp(
      0,
      math.max(0, size.width - 1),
    );
    final y = (point.y * size.height).round().clamp(
      0,
      math.max(0, size.height - 1),
    );
    return PixelPoint(x.toInt(), y.toInt());
  }

  /// Turns a pixel position back into a normalised point.
  NormalizedPoint toNormalized(
    double x,
    double y,
    double width,
    double height,
  ) {
    if (width <= 0 || height <= 0) return const NormalizedPoint(0, 0);
    return NormalizedPoint(
      (x / width).clamp(0.0, 1.0),
      (y / height).clamp(0.0, 1.0),
    );
  }

  /// Turns a normalised stroke width into pixels.
  ///
  /// Widths are stored against the image's shorter side, so a line looks the
  /// same thickness whether the photo is portrait or landscape, and at any
  /// resolution.
  int strokeWidthInPixels(double normalizedWidth, PixelSize size) {
    final shorter = math.min(size.width, size.height);
    final pixels = (normalizedWidth.abs() * shorter).round();
    return math.max(1, pixels);
  }

  /// The rectangle a two-point shape covers, with the corners put in order.
  ///
  /// A shape dragged up and to the left has its end before its start, so the
  /// edges are sorted here rather than in every drawing call.
  NormalizedRect shapeBounds(NormalizedPoint start, NormalizedPoint end) {
    return NormalizedRect(
      left: math.min(start.x, end.x),
      top: math.min(start.y, end.y),
      right: math.max(start.x, end.x),
      bottom: math.max(start.y, end.y),
    );
  }

  /// The smallest box that holds every point of [stroke].
  ///
  /// Used to hit-test a tap against a doodle, and to skip a stroke that is
  /// entirely outside the crop.
  NormalizedRect strokeBounds(DoodleStroke stroke) {
    if (stroke.points.isEmpty) return NormalizedRect.full;

    var left = stroke.points.first.x;
    var top = stroke.points.first.y;
    var right = left;
    var bottom = top;

    for (final point in stroke.points) {
      left = math.min(left, point.x);
      top = math.min(top, point.y);
      right = math.max(right, point.x);
      bottom = math.max(bottom, point.y);
    }

    return NormalizedRect(left: left, top: top, right: right, bottom: bottom);
  }

  /// The two points that make an arrow head at the [end] of a line.
  ///
  /// The head is drawn as two short lines angled back from the tip. Its size
  /// grows with the stroke width, so a thick arrow does not end in a tiny
  /// point.
  List<PixelPoint> arrowHeadPoints(
    NormalizedPoint start,
    NormalizedPoint end,
    PixelSize size,
    int strokePixels,
  ) {
    final tip = toPixel(end, size);
    final tail = toPixel(start, size);

    final dx = (tip.x - tail.x).toDouble();
    final dy = (tip.y - tail.y).toDouble();
    final length = math.sqrt(dx * dx + dy * dy);
    // A zero-length drag has no direction to point in, so there is no head.
    if (length < 1) return const <PixelPoint>[];

    final angle = math.atan2(dy, dx);
    final headLength = math.max(strokePixels * 4.0, length * 0.18);
    const spread = math.pi / 7;

    PixelPoint barb(double offsetAngle) {
      final x = tip.x - headLength * math.cos(angle + offsetAngle);
      final y = tip.y - headLength * math.sin(angle + offsetAngle);
      return PixelPoint(
        x.round().clamp(0, math.max(0, size.width - 1)).toInt(),
        y.round().clamp(0, math.max(0, size.height - 1)).toInt(),
      );
    }

    return <PixelPoint>[barb(spread), barb(-spread)];
  }

  /// The font height in pixels for a text layer on an image of [size].
  int fontSizeInPixels(double fontScale, PixelSize size) {
    final shorter = math.min(size.width, size.height);
    final pixels = (fontScale.abs() * shorter).round();
    return math.max(8, pixels);
  }

  /// Whether [layer] would draw anything at all.
  ///
  /// A stroke with one point, a shape dragged nowhere, and empty text are all
  /// normal results of a stray tap, and are simply skipped.
  bool isDrawable(MarkupLayer layer) {
    switch (layer) {
      case DoodleStroke():
        return layer.points.length >= 2;
      case ShapeAnnotation():
        final bounds = shapeBounds(layer.start, layer.end);
        if (layer.shape == ShapeKind.line || layer.shape == ShapeKind.arrow) {
          // A line only needs length in one direction to be visible.
          return bounds.width > 0.001 || bounds.height > 0.001;
        }
        return bounds.width > 0.001 && bounds.height > 0.001;
      case TextAnnotation():
        return layer.text.trim().isNotEmpty;
    }
  }
}

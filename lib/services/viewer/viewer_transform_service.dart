import 'dart:math' as math;
import 'dart:ui';

import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/viewer_transform.dart';
import 'package:vector_math/vector_math_64.dart';

/// Pure zoom, rotation, and dismiss maths for the fullscreen image viewer.
///
/// It holds no state and touches no widget, so every rule below is unit tested
/// without a device. The viewer widget only asks it questions and draws the
/// answers.
class ViewerTransformService {
  const ViewerTransformService();

  /// Smallest zoom the viewer allows.
  static double get minScale => AppConstants.viewerMinScale;

  /// Largest zoom the viewer allows.
  static double get maxScale => AppConstants.viewerMaxScale;

  /// Keeps a zoom level inside the supported range.
  ///
  /// A NaN or infinite scale (which a pinch can produce on a degenerate
  /// gesture) falls back to the fitted size instead of breaking the layout.
  double clampScale(double scale) {
    if (scale.isNaN || scale.isInfinite) return minScale;
    return scale.clamp(minScale, maxScale);
  }

  /// The zoom a double tap should jump to.
  ///
  /// Tapping an unzoomed image zooms in; tapping an already zoomed image goes
  /// back to the fitted size.
  double doubleTapTargetScale(double currentScale) {
    if (currentScale > minScale + 0.01) return minScale;
    return clampScale(AppConstants.viewerDoubleTapScale);
  }

  /// Builds the matrix that zooms to [targetScale] around [focalPoint].
  ///
  /// [focalPoint] is where the user tapped, in the coordinate space of the
  /// [viewportSize] box. Zooming around that point keeps whatever the user
  /// aimed at under their finger.
  Matrix4 zoomMatrix({
    required double targetScale,
    required Offset focalPoint,
    required Size viewportSize,
  }) {
    final scale = clampScale(targetScale);
    if (scale <= minScale) return Matrix4.identity();

    // Move the focal point to the origin, scale, then move it back.
    final dx = -focalPoint.dx * (scale - 1);
    final dy = -focalPoint.dy * (scale - 1);
    return Matrix4.identity()
      ..translateByDouble(dx, dy, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);
  }

  /// Reads the zoom level out of an `InteractiveViewer` matrix.
  double scaleOf(Matrix4 matrix) {
    final row = matrix.getRow(0);
    final scale = math.sqrt(row.x * row.x + row.y * row.y);
    return clampScale(scale);
  }

  /// The next rotation when the user taps "rotate right".
  int rotateRight(int currentDegrees) => normalizeRotation(currentDegrees + 90);

  /// The next rotation when the user taps "rotate left".
  int rotateLeft(int currentDegrees) => normalizeRotation(currentDegrees - 90);

  /// Folds any angle into one of 0, 90, 180, or 270 degrees.
  ///
  /// Rotation is a view-only preview. Nothing is written back to the file, so
  /// the value only ever has to be good enough to draw.
  int normalizeRotation(int degrees) {
    final snapped = (degrees / 90).round() * 90;
    final wrapped = snapped % 360;
    return wrapped < 0 ? wrapped + 360 : wrapped;
  }

  /// Rotation expressed in radians, ready for a `Transform.rotate`.
  double rotationRadians(int degrees) =>
      normalizeRotation(degrees) * math.pi / 180;

  /// Whether the image is turned onto its side, so width and height swap.
  bool isQuarterTurned(int degrees) {
    final normalized = normalizeRotation(degrees);
    return normalized == 90 || normalized == 270;
  }

  /// How many 90-degree clockwise quarter turns this rotation represents,
  /// ready for a [RotatedBox].
  int quarterTurns(int degrees) => (normalizeRotation(degrees) ~/ 90) % 4;

  /// Whether a drag may start closing the viewer.
  ///
  /// Only a downward drag on an unzoomed page counts. While zoomed in, the same
  /// drag pans the image instead.
  bool canStartDismiss(ViewerTransform transform, Offset delta) {
    return transform.isAtRest && delta.dy > 0;
  }

  /// How far the dismiss drag has gone, from 0 (untouched) to 1 (released).
  double dismissProgress(double dismissOffset) {
    if (dismissOffset <= 0 || dismissOffset.isNaN) return 0;
    return (dismissOffset / AppConstants.viewerDismissDistance).clamp(0.0, 1.0);
  }

  /// Background opacity behind a page being dragged away.
  ///
  /// The backdrop fades from solid to clear as the page falls, which is what
  /// makes the gesture feel like a dismissal rather than a scroll.
  double backdropOpacity(double dismissOffset) =>
      1.0 - dismissProgress(dismissOffset) * 0.85;

  /// Scale of a page being dragged away, so it shrinks slightly as it goes.
  double dismissScale(double dismissOffset) =>
      1.0 - dismissProgress(dismissOffset) * 0.2;

  /// Whether releasing the drag here should close the viewer.
  ///
  /// A short drag closes it too when it was flicked fast enough, which matches
  /// what people expect from a flick-to-close gesture.
  bool shouldDismissOnRelease({
    required double dismissOffset,
    required double velocityPixelsPerSecond,
  }) {
    if (dismissOffset <= 0) return false;
    if (velocityPixelsPerSecond > 700) return true;
    return dismissOffset >= AppConstants.viewerDismissDistance;
  }
}

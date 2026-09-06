import 'package:flutter/foundation.dart';

/// Immutable zoom, rotation, and dismiss state of one page in the viewer.
///
/// The widget owns no logic of its own: it hands the current transform plus a
/// gesture to `ViewerTransformService` and draws whatever comes back.
@immutable
class ViewerTransform {
  /// Current zoom level. 1.0 means the image is fitted to the screen.
  final double scale;

  /// Rotation applied to the view, always one of 0, 90, 180, or 270.
  final int rotationDegrees;

  /// How far the user has dragged the page down, in logical pixels.
  final double dismissOffset;

  const ViewerTransform({
    this.scale = 1.0,
    this.rotationDegrees = 0,
    this.dismissOffset = 0,
  });

  /// A fresh, unzoomed, unrotated page.
  static const ViewerTransform initial = ViewerTransform();

  /// Whether the image sits at its fitted size.
  ///
  /// Paging between items and the swipe-down dismiss are only allowed while
  /// this is true, so a zoomed-in pan never closes the viewer by accident.
  bool get isAtRest => scale <= 1.0001;

  /// Whether the user is currently dragging the page away.
  bool get isDismissing => dismissOffset > 0;

  ViewerTransform copyWith({
    double? scale,
    int? rotationDegrees,
    double? dismissOffset,
  }) {
    return ViewerTransform(
      scale: scale ?? this.scale,
      rotationDegrees: rotationDegrees ?? this.rotationDegrees,
      dismissOffset: dismissOffset ?? this.dismissOffset,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ViewerTransform &&
          runtimeType == other.runtimeType &&
          scale == other.scale &&
          rotationDegrees == other.rotationDegrees &&
          dismissOffset == other.dismissOffset;

  @override
  int get hashCode => Object.hash(scale, rotationDegrees, dismissOffset);

  @override
  String toString() =>
      'ViewerTransform(scale: $scale, rotation: $rotationDegrees, '
      'dismissOffset: $dismissOffset)';
}

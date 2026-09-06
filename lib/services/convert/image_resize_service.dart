import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/convert/resize_spec.dart';

/// A width and height in whole pixels.
@immutable
class TargetSize {
  final int width;
  final int height;

  const TargetSize(this.width, this.height);

  /// How many pixels the picture holds.
  int get pixelCount => width * height;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TargetSize &&
          runtimeType == other.runtimeType &&
          width == other.width &&
          height == other.height;

  @override
  int get hashCode => Object.hash(width, height);

  @override
  String toString() => '${width}x$height';
}

/// Works out the pixel size a resize should produce.
///
/// This is pure maths on purpose: no files, no decoding, no platform. It is
/// the piece that decides what the user actually gets, so it is the piece
/// that is easiest to get wrong and the one worth testing hardest.
class ImageResizeService {
  const ImageResizeService();

  /// The size [spec] asks for, given a source of [sourceWidth] by
  /// [sourceHeight].
  ///
  /// The result is never smaller than 1 pixel on a side, and never larger
  /// than the allowed maximum, so a mistyped number cannot ask for a
  /// picture the device could not hold.
  TargetSize resolve({
    required int sourceWidth,
    required int sourceHeight,
    required ResizeSpec spec,
  }) {
    final safeWidth = math.max(1, sourceWidth);
    final safeHeight = math.max(1, sourceHeight);

    switch (spec.mode) {
      case ResizeMode.none:
        return TargetSize(safeWidth, safeHeight);

      case ResizeMode.longestSide:
        return _fitLongestSide(safeWidth, safeHeight, spec.longestSide);

      case ResizeMode.percent:
        final percent = spec.percent.clamp(
          AppConstants.convertMinPercent,
          AppConstants.convertMaxPercent,
        );
        return _clamp(
          TargetSize(
            (safeWidth * percent / 100).round(),
            (safeHeight * percent / 100).round(),
          ),
        );

      case ResizeMode.exact:
        final width = spec.width.clamp(1, AppConstants.convertMaxLongestSide);
        final height = spec.height.clamp(1, AppConstants.convertMaxLongestSide);
        if (!spec.keepAspect) {
          return _clamp(TargetSize(width, height));
        }
        // Keeping the shape means fitting inside the box the user typed,
        // so nothing is stretched and nothing is cut off.
        return _containWithin(safeWidth, safeHeight, width, height);
    }
  }

  /// Whether [spec] would actually change a source of this size.
  ///
  /// When it would not, the encoder can skip the resize step entirely and
  /// save a whole pass over the pixels.
  bool changesSize({
    required int sourceWidth,
    required int sourceHeight,
    required ResizeSpec spec,
  }) {
    final target = resolve(
      sourceWidth: sourceWidth,
      sourceHeight: sourceHeight,
      spec: spec,
    );
    return target.width != sourceWidth || target.height != sourceHeight;
  }

  /// Fits a picture inside [maxSide] on its longest edge, keeping the shape.
  ///
  /// A picture already smaller than [maxSide] is left alone: making it
  /// bigger would only invent detail that is not there.
  TargetSize fitWithin(int width, int height, int maxSide) {
    final longest = math.max(width, height);
    if (longest <= maxSide || longest == 0) {
      return TargetSize(math.max(1, width), math.max(1, height));
    }
    final scale = maxSide / longest;
    return TargetSize(
      math.max(1, (width * scale).round()),
      math.max(1, (height * scale).round()),
    );
  }

  TargetSize _fitLongestSide(int width, int height, int requested) {
    final maxSide = requested.clamp(
      AppConstants.convertMinLongestSide,
      AppConstants.convertMaxLongestSide,
    );
    final longest = math.max(width, height);
    final scale = maxSide / longest;
    return _clamp(
      TargetSize(
        math.max(1, (width * scale).round()),
        math.max(1, (height * scale).round()),
      ),
    );
  }

  TargetSize _containWithin(
    int width,
    int height,
    int boxWidth,
    int boxHeight,
  ) {
    final scale = math.min(boxWidth / width, boxHeight / height);
    return _clamp(
      TargetSize(
        math.max(1, (width * scale).round()),
        math.max(1, (height * scale).round()),
      ),
    );
  }

  /// Pulls a size back inside the allowed limits, keeping the shape.
  TargetSize _clamp(TargetSize size) {
    final longest = math.max(size.width, size.height);
    if (longest <= AppConstants.convertMaxLongestSide) {
      return TargetSize(math.max(1, size.width), math.max(1, size.height));
    }
    final scale = AppConstants.convertMaxLongestSide / longest;
    return TargetSize(
      math.max(1, (size.width * scale).round()),
      math.max(1, (size.height * scale).round()),
    );
  }
}

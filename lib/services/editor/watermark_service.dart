import 'dart:math' as math;

import 'package:in_sreerajp_imgvidgal/models/editor/watermark_config.dart';
import 'package:in_sreerajp_imgvidgal/services/editor/crop_transform_service.dart';

/// Where a watermark ends up, in whole pixels.
class WatermarkPlacement {
  final int left;
  final int top;
  final int width;
  final int height;

  const WatermarkPlacement({
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
      other is WatermarkPlacement &&
          runtimeType == other.runtimeType &&
          left == other.left &&
          top == other.top &&
          width == other.width &&
          height == other.height;

  @override
  int get hashCode => Object.hash(left, top, width, height);

  @override
  String toString() => 'WatermarkPlacement($left, $top, ${width}x$height)';
}

/// Works out what a watermark says and where it goes.
///
/// Placement is pure maths against the image size, so the same call gives the
/// preview and the saved copy the same corner and the same margin.
class WatermarkService {
  const WatermarkService();

  /// Formats [date] using the pattern in [config].
  ///
  /// Only the handful of fields a photo stamp needs are supported, which
  /// avoids pulling a date library into the render isolate. An unknown
  /// pattern falls back to the default rather than failing the save.
  String formatTimestamp(DateTime date, String pattern) {
    final safePattern = pattern.trim().isEmpty ? 'yyyy-MM-dd HH:mm' : pattern;

    String two(int value) => value.toString().padLeft(2, '0');

    // Longest tokens first, so 'yyyy' is not eaten by 'yy'.
    return safePattern
        .replaceAll('yyyy', date.year.toString().padLeft(4, '0'))
        .replaceAll('MM', two(date.month))
        .replaceAll('dd', two(date.day))
        .replaceAll('HH', two(date.hour))
        .replaceAll('mm', two(date.minute))
        .replaceAll('ss', two(date.second));
  }

  /// The text a watermark draws, or an empty string when it draws a logo.
  ///
  /// [captureDate] is the photo's own date. When it is missing, the timestamp
  /// mode falls back to now, because a stamp with no date at all would look
  /// like a bug to the user.
  String resolveText(WatermarkConfig config, {DateTime? captureDate}) {
    switch (config.mode) {
      case WatermarkMode.none:
      case WatermarkMode.logo:
        return '';
      case WatermarkMode.text:
        return config.text.trim();
      case WatermarkMode.timestamp:
        return formatTimestamp(
          captureDate ?? DateTime.now(),
          config.timestampPattern,
        );
    }
  }

  /// The height, in pixels, a watermark of this scale should be.
  ///
  /// Scale is against the image's shorter side so a stamp keeps its
  /// proportion whichever way round the photo is.
  int heightInPixels(double scale, PixelSize imageSize) {
    final shorter = math.min(imageSize.width, imageSize.height);
    final pixels = (scale.abs().clamp(0.005, 0.5) * shorter).round();
    return math.max(8, pixels);
  }

  /// The gap from the edge, in pixels.
  int marginInPixels(double margin, PixelSize imageSize) {
    final shorter = math.min(imageSize.width, imageSize.height);
    final pixels = (margin.abs().clamp(0.0, 0.4) * shorter).round();
    return math.max(0, pixels);
  }

  /// Where a stamp of [contentWidth] by [contentHeight] pixels sits.
  ///
  /// The result is always inside the image: a stamp bigger than the photo is
  /// pulled back to the top-left corner instead of being drawn off the edge.
  WatermarkPlacement placement({
    required WatermarkConfig config,
    required PixelSize imageSize,
    required int contentWidth,
    required int contentHeight,
  }) {
    final width = math.max(1, math.min(contentWidth, imageSize.width));
    final height = math.max(1, math.min(contentHeight, imageSize.height));
    final margin = marginInPixels(config.margin, imageSize);

    final maxLeft = math.max(0, imageSize.width - width);
    final maxTop = math.max(0, imageSize.height - height);

    late final int left;
    late final int top;

    switch (config.position) {
      case WatermarkPosition.topLeft:
        left = math.min(margin, maxLeft);
        top = math.min(margin, maxTop);
      case WatermarkPosition.topCenter:
        left = maxLeft ~/ 2;
        top = math.min(margin, maxTop);
      case WatermarkPosition.topRight:
        left = math.max(0, maxLeft - margin);
        top = math.min(margin, maxTop);
      case WatermarkPosition.centerLeft:
        left = math.min(margin, maxLeft);
        top = maxTop ~/ 2;
      case WatermarkPosition.center:
        left = maxLeft ~/ 2;
        top = maxTop ~/ 2;
      case WatermarkPosition.centerRight:
        left = math.max(0, maxLeft - margin);
        top = maxTop ~/ 2;
      case WatermarkPosition.bottomLeft:
        left = math.min(margin, maxLeft);
        top = math.max(0, maxTop - margin);
      case WatermarkPosition.bottomCenter:
        left = maxLeft ~/ 2;
        top = math.max(0, maxTop - margin);
      case WatermarkPosition.bottomRight:
        left = math.max(0, maxLeft - margin);
        top = math.max(0, maxTop - margin);
    }

    return WatermarkPlacement(
      left: left,
      top: top,
      width: width,
      height: height,
    );
  }

  /// The size a logo should be drawn at, keeping its own proportions.
  ///
  /// The logo is scaled to the requested height; a logo with no size at all
  /// (a broken file) reports a single pixel rather than dividing by zero.
  PixelSize logoSize({
    required PixelSize logoNativeSize,
    required int targetHeight,
  }) {
    if (logoNativeSize.width <= 0 || logoNativeSize.height <= 0) {
      return const PixelSize(1, 1);
    }
    final ratio = logoNativeSize.width / logoNativeSize.height;
    final width = math.max(1, (targetHeight * ratio).round());
    return PixelSize(width, math.max(1, targetHeight));
  }

  /// The alpha, 0 to 255, a watermark is drawn with.
  int alphaFor(double opacity) {
    if (opacity.isNaN) return 255;
    return (opacity.clamp(0.0, 1.0) * 255).round();
  }
}

import 'dart:math' as math;

import 'package:image/image.dart' as img;
import 'package:in_sreerajp_imgvidgal/models/editor/markup_layer.dart';
import 'package:in_sreerajp_imgvidgal/services/editor/crop_transform_service.dart';
import 'package:in_sreerajp_imgvidgal/services/editor/markup_geometry_service.dart';
import 'package:in_sreerajp_imgvidgal/services/editor/redaction_service.dart';

/// Draws markup layers onto real pixels.
///
/// All the positions come from [MarkupGeometryService], so this class only
/// turns already-decided coordinates into calls on the `image` package. The
/// split keeps the maths testable and the drawing simple.
class MarkupRenderService {
  final MarkupGeometryService _geometry;

  const MarkupRenderService({
    MarkupGeometryService geometry = const MarkupGeometryService(),
  }) : _geometry = geometry;

  /// Draws every layer in [layers] onto [image], in list order.
  ///
  /// Layers that would draw nothing are skipped, and a layer that fails is
  /// dropped rather than losing the whole save: one bad annotation must not
  /// cost the user their edit.
  img.Image drawLayers(img.Image image, List<MarkupLayer> layers) {
    if (layers.isEmpty) return image;

    final size = PixelSize(image.width, image.height);
    var result = image;

    for (final layer in layers) {
      if (!_geometry.isDrawable(layer)) continue;
      try {
        result = switch (layer) {
          DoodleStroke() => _drawDoodle(result, layer, size),
          ShapeAnnotation() => _drawShape(result, layer, size),
          TextAnnotation() => _drawText(result, layer, size),
        };
      } catch (_) {
        // Keep the rest of the drawing; a single unusable layer is skipped.
        continue;
      }
    }

    return result;
  }

  /// Renders [text] into its own transparent image at the given height.
  ///
  /// The bundled fonts are fixed sizes, so the text is drawn once at the
  /// largest built-in size and then scaled. That gives any requested height
  /// without shipping a font file of our own.
  img.Image? rasterizeText({
    required String text,
    required int targetHeight,
    required int colorArgb,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || targetHeight < 1) return null;

    final font = img.arial48;
    final lineHeight = math.max(1, font.lineHeight);

    var width = 0;
    for (final code in trimmed.codeUnits) {
      final character = font.characters[code];
      // Characters the bitmap font does not have (many scripts are missing)
      // still take a sensible slot, so the text does not bunch up.
      width += character?.xAdvance ?? (font.size ~/ 2);
    }
    if (width < 1) return null;

    final base = img.Image(width: width, height: lineHeight, numChannels: 4);
    // Start fully transparent so only the glyphs land on the photo.
    img.fill(base, color: img.ColorRgba8(0, 0, 0, 0));
    img.drawString(
      base,
      trimmed,
      font: font,
      x: 0,
      y: 0,
      color: RedactionService.colorFromArgb(colorArgb),
    );

    if (targetHeight == lineHeight) return base;

    final scale = targetHeight / lineHeight;
    final targetWidth = math.max(1, (width * scale).round());
    return img.copyResize(
      base,
      width: targetWidth,
      height: targetHeight,
      interpolation: img.Interpolation.cubic,
    );
  }

  img.Image _drawDoodle(img.Image image, DoodleStroke stroke, PixelSize size) {
    final color = _colorWithOpacity(stroke.colorArgb, stroke.opacity);
    final thickness = _geometry.strokeWidthInPixels(stroke.strokeWidth, size);

    var result = image;
    for (var i = 0; i < stroke.points.length - 1; i++) {
      final from = _geometry.toPixel(stroke.points[i], size);
      final to = _geometry.toPixel(stroke.points[i + 1], size);
      result = img.drawLine(
        result,
        x1: from.x,
        y1: from.y,
        x2: to.x,
        y2: to.y,
        color: color,
        thickness: thickness,
        antialias: true,
      );
    }
    return result;
  }

  img.Image _drawShape(img.Image image, ShapeAnnotation shape, PixelSize size) {
    final color = _colorWithOpacity(shape.colorArgb, shape.opacity);
    final thickness = _geometry.strokeWidthInPixels(shape.strokeWidth, size);
    final bounds = _geometry.shapeBounds(shape.start, shape.end);

    switch (shape.shape) {
      case ShapeKind.rectangle:
        final topLeft = _geometry.toPixel(
          NormalizedPoint(bounds.left, bounds.top),
          size,
        );
        final bottomRight = _geometry.toPixel(
          NormalizedPoint(bounds.right, bounds.bottom),
          size,
        );
        if (shape.filled) {
          return img.fillRect(
            image,
            x1: topLeft.x,
            y1: topLeft.y,
            x2: bottomRight.x,
            y2: bottomRight.y,
            color: color,
          );
        }
        return img.drawRect(
          image,
          x1: topLeft.x,
          y1: topLeft.y,
          x2: bottomRight.x,
          y2: bottomRight.y,
          color: color,
          thickness: thickness,
        );

      case ShapeKind.ellipse:
        final topLeft = _geometry.toPixel(
          NormalizedPoint(bounds.left, bounds.top),
          size,
        );
        final bottomRight = _geometry.toPixel(
          NormalizedPoint(bounds.right, bounds.bottom),
          size,
        );
        final centerX = (topLeft.x + bottomRight.x) ~/ 2;
        final centerY = (topLeft.y + bottomRight.y) ~/ 2;
        // The package draws circles rather than ellipses, so the smaller half
        // is used and the result stays inside what the user dragged.
        final radius = math.max(
          1,
          math.min(
            (bottomRight.x - topLeft.x) ~/ 2,
            (bottomRight.y - topLeft.y) ~/ 2,
          ),
        );
        if (shape.filled) {
          return img.fillCircle(
            image,
            x: centerX,
            y: centerY,
            radius: radius,
            color: color,
          );
        }
        return img.drawCircle(
          image,
          x: centerX,
          y: centerY,
          radius: radius,
          color: color,
        );

      case ShapeKind.line:
      case ShapeKind.arrow:
        final from = _geometry.toPixel(shape.start, size);
        final to = _geometry.toPixel(shape.end, size);
        var result = img.drawLine(
          image,
          x1: from.x,
          y1: from.y,
          x2: to.x,
          y2: to.y,
          color: color,
          thickness: thickness,
          antialias: true,
        );
        if (shape.shape == ShapeKind.line) return result;

        for (final barb in _geometry.arrowHeadPoints(
          shape.start,
          shape.end,
          size,
          thickness,
        )) {
          result = img.drawLine(
            result,
            x1: to.x,
            y1: to.y,
            x2: barb.x,
            y2: barb.y,
            color: color,
            thickness: thickness,
            antialias: true,
          );
        }
        return result;
    }
  }

  img.Image _drawText(
    img.Image image,
    TextAnnotation annotation,
    PixelSize size,
  ) {
    final height = _geometry.fontSizeInPixels(annotation.fontScale, size);
    final raster = rasterizeText(
      text: annotation.text,
      targetHeight: height,
      colorArgb: _applyOpacity(annotation.colorArgb, annotation.opacity),
    );
    if (raster == null) return image;

    final origin = _geometry.toPixel(annotation.position, size);
    // Pull the text back inside the photo if it was placed near an edge.
    final left = origin.x
        .clamp(0, math.max(0, size.width - raster.width))
        .toInt();
    final top = origin.y
        .clamp(0, math.max(0, size.height - raster.height))
        .toInt();

    var result = image;
    if (annotation.hasBackground) {
      final padding = math.max(2, height ~/ 6);
      result = img.fillRect(
        result,
        x1: math.max(0, left - padding),
        y1: math.max(0, top - padding),
        x2: math.min(size.width - 1, left + raster.width + padding),
        y2: math.min(size.height - 1, top + raster.height + padding),
        color: RedactionService.colorFromArgb(
          _applyOpacity(annotation.backgroundArgb, annotation.opacity),
        ),
      );
    }

    return img.compositeImage(result, raster, dstX: left, dstY: top);
  }

  /// The layer colour with its opacity folded into the alpha channel.
  img.Color _colorWithOpacity(int argb, double opacity) =>
      RedactionService.colorFromArgb(_applyOpacity(argb, opacity));

  int _applyOpacity(int argb, double opacity) {
    final safe = opacity.isNaN ? 1.0 : opacity.clamp(0.0, 1.0);
    final alpha = (((argb >> 24) & 0xFF) * safe).round().clamp(0, 255);
    return (alpha << 24) | (argb & 0x00FFFFFF);
  }
}

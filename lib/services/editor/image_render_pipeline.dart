import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/edit_session.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/tone_adjustments.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/watermark_config.dart';
import 'package:in_sreerajp_imgvidgal/services/editor/crop_transform_service.dart';
import 'package:in_sreerajp_imgvidgal/services/editor/filter_preset_service.dart';
import 'package:in_sreerajp_imgvidgal/services/editor/hsl_service.dart';
import 'package:in_sreerajp_imgvidgal/services/editor/markup_render_service.dart';
import 'package:in_sreerajp_imgvidgal/services/editor/redaction_service.dart';
import 'package:in_sreerajp_imgvidgal/services/editor/selective_mask_service.dart';
import 'package:in_sreerajp_imgvidgal/services/editor/tone_adjustment_service.dart';
import 'package:in_sreerajp_imgvidgal/services/editor/watermark_service.dart';

/// The file type the render writes out.
enum RenderFormat {
  jpeg,
  png;

  /// The extension this format uses, without the dot.
  String get extension => this == RenderFormat.jpeg ? 'jpg' : 'png';

  /// The format that suits a file called [fileName].
  ///
  /// Anything that is not clearly a JPEG becomes a PNG, because PNG keeps
  /// transparency and never loses quality a second time.
  static RenderFormat forFileName(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return RenderFormat.jpeg;
    }
    return RenderFormat.png;
  }
}

/// Everything one render needs, in a shape that can cross into an isolate.
///
/// Only plain values are carried: bytes, a JSON session, and numbers. Service
/// objects stay on this side of the boundary.
@immutable
class RenderRequest {
  /// Bytes of the original photo.
  final Uint8List sourceBytes;

  /// The edit, as JSON, so nothing but data crosses the isolate boundary.
  final String sessionJson;

  /// Longest side of the result, or null to keep the full resolution.
  final int? maxSide;

  /// The file type to encode.
  final RenderFormat format;

  /// JPEG quality, 0 to 100. Ignored for PNG.
  final int quality;

  /// Bytes of the watermark logo, or null when there is no logo.
  final Uint8List? logoBytes;

  /// The photo's capture date, used by the timestamp watermark.
  final DateTime? captureDate;

  const RenderRequest({
    required this.sourceBytes,
    required this.sessionJson,
    this.maxSide,
    this.format = RenderFormat.jpeg,
    this.quality = AppConstants.editorJpegQuality,
    this.logoBytes,
    this.captureDate,
  });
}

/// What a render produced.
@immutable
class RenderResult {
  /// The finished image, encoded and ready to write.
  final Uint8List bytes;

  final int width;
  final int height;

  const RenderResult({
    required this.bytes,
    required this.width,
    required this.height,
  });
}

/// Thrown when a photo cannot be turned into a picture at all.
///
/// The editor catches it and shows a message, because a broken or
/// unsupported file must never take the app down.
class ImageRenderException implements Exception {
  final String message;

  const ImageRenderException(this.message);

  @override
  String toString() => 'ImageRenderException: $message';
}

/// Turns an [EditSession] into real pixels.
///
/// The stages always run in the same order, on the preview and on the saved
/// copy alike:
///
/// 1. geometry — perspective, straighten, quarter turns, flips, crop
/// 2. redaction — blur, pixelate, or blackout on the visible image
/// 3. tone and filter — the lookup tables plus saturation and vibrance
/// 4. markup — doodles, shapes, and text
/// 5. watermark — the stamp, last so nothing covers it
///
/// Nothing in this class touches the file system. It takes bytes and gives
/// bytes back, which is what lets the whole render run in an isolate.
class ImageRenderPipeline {
  final CropTransformService _cropService;
  final ToneAdjustmentService _toneService;
  final FilterPresetService _filterService;
  final RedactionService _redactionService;
  final SelectiveMaskService _maskService;
  final HslService _hslService;
  final MarkupRenderService _markupService;
  final WatermarkService _watermarkService;

  const ImageRenderPipeline({
    CropTransformService cropService = const CropTransformService(),
    ToneAdjustmentService toneService = const ToneAdjustmentService(),
    FilterPresetService filterService = const FilterPresetService(),
    RedactionService redactionService = const RedactionService(),
    SelectiveMaskService maskService = const SelectiveMaskService(),
    HslService hslService = const HslService(),
    MarkupRenderService markupService = const MarkupRenderService(),
    WatermarkService watermarkService = const WatermarkService(),
  }) : _cropService = cropService,
       _toneService = toneService,
       _filterService = filterService,
       _redactionService = redactionService,
       _maskService = maskService,
       _hslService = hslService,
       _markupService = markupService,
       _watermarkService = watermarkService;

  /// Renders [request] on a background isolate.
  ///
  /// A full-resolution photo takes long enough that doing it on the UI thread
  /// would freeze the screen, so every call goes through `compute`.
  Future<RenderResult> renderInBackground(RenderRequest request) {
    return compute(_renderEntryPoint, request);
  }

  /// Renders [request] on the calling thread.
  ///
  /// Used by the isolate entry point and by the tests. Application code
  /// should prefer [renderInBackground].
  RenderResult render(RenderRequest request) {
    final decoded = decode(request.sourceBytes);
    final session = EditSession.fromJson(request.sessionJson);

    var image = decoded;

    image = applyGeometry(image, session);
    image = _redactionService.applyAll(image, session.redactions);
    image = _maskService.applyMasks(image, session.selectiveMasks);
    image = applyToneAndFilter(image, session);
    image = _markupService.drawLayers(image, session.markup);
    image = applyWatermark(
      image,
      session.watermark,
      logoBytes: request.logoBytes,
      captureDate: request.captureDate,
    );

    final maxSide = request.maxSide;
    if (maxSide != null && maxSide > 0) {
      image = _fitWithin(image, maxSide);
    }

    return RenderResult(
      bytes: encode(image, request.format, request.quality),
      width: image.width,
      height: image.height,
    );
  }

  /// Decodes photo bytes, or throws [ImageRenderException] if it cannot.
  ///
  /// A corrupt or unsupported file is a normal thing to meet on a device, so
  /// the failure is a plain exception the editor can turn into a message.
  img.Image decode(Uint8List bytes) {
    if (bytes.isEmpty) {
      throw const ImageRenderException('The image file is empty');
    }
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        throw const ImageRenderException('The image format is not supported');
      }
      return decoded;
    } on ImageRenderException {
      rethrow;
    } catch (error) {
      throw ImageRenderException('The image could not be read: $error');
    }
  }

  /// Encodes [image] in [format].
  Uint8List encode(img.Image image, RenderFormat format, int quality) {
    switch (format) {
      case RenderFormat.jpeg:
        return img.encodeJpg(image, quality: quality.clamp(1, 100));
      case RenderFormat.png:
        return img.encodePng(image);
    }
  }

  /// Runs the perspective, straighten, rotation, flip, and crop stages.
  img.Image applyGeometry(img.Image image, EditSession session) {
    final transform = session.crop;
    if (transform.isIdentity) return image;

    var result = image;

    // 1. Perspective: pull the four corners out to the full rectangle.
    if (!transform.perspective.isIdentity) {
      final corners = _cropService.perspectiveCorners(
        transform.perspective,
        PixelSize(result.width, result.height),
      );
      result = img.copyRectify(
        result,
        topLeft: img.Point(corners[0][0], corners[0][1]),
        topRight: img.Point(corners[1][0], corners[1][1]),
        bottomRight: img.Point(corners[2][0], corners[2][1]),
        bottomLeft: img.Point(corners[3][0], corners[3][1]),
        interpolation: img.Interpolation.linear,
      );
    }

    // 2. Straighten, then cut off the blank corners the tilt leaves behind.
    final straighten = _cropService.clampStraighten(
      transform.straightenDegrees,
    );
    if (straighten.abs() > 0.0001) {
      final before = PixelSize(result.width, result.height);
      result = img.copyRotate(result, angle: straighten);
      final inner = _cropService.largestInnerRect(before, straighten);
      result = _safeCrop(result, inner);
    }

    // 3. Quarter turns and mirroring.
    final turns = _cropService.normalizeQuarterTurns(transform.quarterTurns);
    if (turns != 0) {
      result = img.copyRotate(result, angle: turns * 90);
    }
    if (transform.flipHorizontal && transform.flipVertical) {
      result = img.copyFlip(result, direction: img.FlipDirection.both);
    } else if (transform.flipHorizontal) {
      result = img.copyFlip(result, direction: img.FlipDirection.horizontal);
    } else if (transform.flipVertical) {
      result = img.copyFlip(result, direction: img.FlipDirection.vertical);
    }

    // 4. The crop box the user dragged, applied last so it is in the same
    //    coordinates the editor was showing.
    if (!transform.rect.isFull) {
      final rect = _cropService.toPixelRect(
        transform.rect,
        PixelSize(result.width, result.height),
      );
      result = _safeCrop(result, rect);
    }

    return result;
  }

  /// Runs the tone sliders, the curves, and the chosen filter.
  ///
  /// The manual sliders and the preset are added together first, so the two
  /// stages become a single pass over the pixels.
  img.Image applyToneAndFilter(img.Image image, EditSession session) {
    final definition = _filterService.resolve(session.filter);
    final combined = combineAdjustments(session.tone, definition.adjustments);
    final monochrome = _filterService.monochromeStrength(session.filter);
    final tintStrength = definition.tintStrength.clamp(0.0, 1.0);

    if (combined.isNeutral && monochrome <= 0 && tintStrength <= 0) {
      return image;
    }

    final tables = _toneService.buildTables(combined);
    final needsColorPass = tables.needsColorPass;

    final tintRed = (definition.tintArgb >> 16) & 0xFF;
    final tintGreen = (definition.tintArgb >> 8) & 0xFF;
    final tintBlue = definition.tintArgb & 0xFF;

    for (final pixel in image) {
      var red = tables.red[pixel.r.round().clamp(0, 255)];
      var green = tables.green[pixel.g.round().clamp(0, 255)];
      var blue = tables.blue[pixel.b.round().clamp(0, 255)];

      if (monochrome > 0) {
        final grey = _toneService.luminance(red, green, blue).round();
        red = _mix(red, grey, monochrome);
        green = _mix(green, grey, monochrome);
        blue = _mix(blue, grey, monochrome);
      }

      if (tintStrength > 0) {
        // The tint keeps the pixel's own brightness and only borrows the
        // preset's hue, so a sepia photo still has light and dark areas.
        final grey = _toneService.luminance(red, green, blue) / 255;
        red = _mix(red, (tintRed * grey).round(), tintStrength);
        green = _mix(green, (tintGreen * grey).round(), tintStrength);
        blue = _mix(blue, (tintBlue * grey).round(), tintStrength);
      }

      if (needsColorPass) {
        final adjusted = _toneService.applyColor(
          red,
          green,
          blue,
          tables.saturation,
          tables.vibrance,
        );
        red = adjusted[0];
        green = adjusted[1];
        blue = adjusted[2];
      }

      pixel
        ..r = red
        ..g = green
        ..b = blue;
    }

    // HSL colour tuner runs after the main tone loop so the user's
    // per-colour adjustments see the already-graded image.
    if (!combined.hslAdjustments.isNeutral) {
      image = _hslService.applyHsl(image, combined.hslAdjustments);
    }

    return image;
  }

  /// Stamps the watermark on, as the very last thing drawn.
  img.Image applyWatermark(
    img.Image image,
    WatermarkConfig config, {
    Uint8List? logoBytes,
    DateTime? captureDate,
  }) {
    if (config.isNone) return image;

    final size = PixelSize(image.width, image.height);
    final height = _watermarkService.heightInPixels(config.scale, size);

    if (config.mode == WatermarkMode.logo) {
      if (logoBytes == null || logoBytes.isEmpty) return image;
      img.Image? logo;
      try {
        logo = img.decodeImage(logoBytes);
      } catch (_) {
        // An unreadable logo simply means no watermark, never a failed save.
        logo = null;
      }
      if (logo == null) return image;

      final target = _watermarkService.logoSize(
        logoNativeSize: PixelSize(logo.width, logo.height),
        targetHeight: height,
      );
      final resized = img.copyResize(
        logo,
        width: target.width,
        height: target.height,
        interpolation: img.Interpolation.cubic,
      );
      final placement = _watermarkService.placement(
        config: config,
        imageSize: size,
        contentWidth: resized.width,
        contentHeight: resized.height,
      );
      return img.compositeImage(
        image,
        resized,
        dstX: placement.left,
        dstY: placement.top,
        blend: img.BlendMode.alpha,
      );
    }

    final text = _watermarkService.resolveText(
      config,
      captureDate: captureDate,
    );
    if (text.isEmpty) return image;

    final alpha = _watermarkService.alphaFor(config.opacity);
    final tinted = (alpha << 24) | (config.colorArgb & 0x00FFFFFF);
    final raster = _markupService.rasterizeText(
      text: text,
      targetHeight: height,
      colorArgb: tinted,
    );
    if (raster == null) return image;

    final placement = _watermarkService.placement(
      config: config,
      imageSize: size,
      contentWidth: raster.width,
      contentHeight: raster.height,
    );
    return img.compositeImage(
      image,
      raster,
      dstX: placement.left,
      dstY: placement.top,
      blend: img.BlendMode.alpha,
    );
  }

  /// Adds a preset's slider positions on top of the user's own.
  ///
  /// Values are added and then pulled back into the -1 to 1 range, so a
  /// strong preset on top of a strong slider cannot run off the scale. The
  /// user's curves always win, because a preset never sets one.
  ToneAdjustments combineAdjustments(
    ToneAdjustments user,
    ToneAdjustments preset,
  ) {
    if (preset.isNeutral) return user;

    double add(double a, double b) => (a + b).clamp(-1.0, 1.0);

    return user.copyWith(
      exposure: add(user.exposure, preset.exposure),
      contrast: add(user.contrast, preset.contrast),
      highlights: add(user.highlights, preset.highlights),
      shadows: add(user.shadows, preset.shadows),
      temperature: add(user.temperature, preset.temperature),
      tint: add(user.tint, preset.tint),
      vibrance: add(user.vibrance, preset.vibrance),
      saturation: add(user.saturation, preset.saturation),
    );
  }

  /// The size a preview should be rendered at for a source of [size].
  ///
  /// Shrinking the preview is what keeps the sliders smooth: the same maths
  /// runs, just on far fewer pixels.
  int previewMaxSide(PixelSize size) {
    final longest = math.max(size.width, size.height);
    if (longest <= AppConstants.editorPreviewMaxSide) return longest;
    return AppConstants.editorPreviewMaxSide;
  }

  /// Shrinks [image] so its longest side is no more than [maxSide].
  img.Image _fitWithin(img.Image image, int maxSide) {
    final longest = math.max(image.width, image.height);
    if (longest <= maxSide) return image;

    final scale = maxSide / longest;
    return img.copyResize(
      image,
      width: math.max(1, (image.width * scale).round()),
      height: math.max(1, (image.height * scale).round()),
      interpolation: img.Interpolation.average,
    );
  }

  /// Crops [image] to [rect], never asking for pixels that are not there.
  img.Image _safeCrop(img.Image image, PixelRect rect) {
    final left = rect.left.clamp(0, math.max(0, image.width - 1)).toInt();
    final top = rect.top.clamp(0, math.max(0, image.height - 1)).toInt();
    final width = rect.width.clamp(1, image.width - left).toInt();
    final height = rect.height.clamp(1, image.height - top).toInt();

    return img.copyCrop(image, x: left, y: top, width: width, height: height);
  }

  /// Blends [from] toward [to] by [amount], 0 to 1.
  int _mix(int from, int to, double amount) =>
      (from + (to - from) * amount).round().clamp(0, 255);
}

/// The isolate entry point. It must be a top level function.
RenderResult _renderEntryPoint(RenderRequest request) {
  return const ImageRenderPipeline().render(request);
}

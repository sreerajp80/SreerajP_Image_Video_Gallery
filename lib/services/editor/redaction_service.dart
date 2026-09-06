import 'dart:math' as math;

import 'package:image/image.dart' as img;
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/redaction_region.dart';
import 'package:in_sreerajp_imgvidgal/services/editor/crop_transform_service.dart';

/// Hides parts of a photo so the detail is really gone.
///
/// Redaction runs before every other stage, straight on the decoded pixels.
/// That matters for privacy: the saved copy has no hidden layer that could be
/// peeled back off, because the original pixels were replaced.
class RedactionService {
  final CropTransformService _cropService;

  const RedactionService({
    CropTransformService cropService = const CropTransformService(),
  }) : _cropService = cropService;

  /// The blur radius, in pixels, for a region of [strength] on this image.
  ///
  /// The radius grows with the image so a face is hidden just as well in a
  /// 12 megapixel photo as in a small preview.
  int blurRadiusFor(double strength, PixelSize regionSize) {
    final safe = strength.isNaN ? 0.5 : strength.clamp(0.0, 1.0);
    final shorter = math.min(regionSize.width, regionSize.height);
    final radius = (shorter * 0.08 * (0.25 + safe)).round();
    return radius.clamp(2, AppConstants.editorMaxBlurRadius).toInt();
  }

  /// The block size, in pixels, for a pixelated region of [strength].
  int pixelateBlockFor(double strength, PixelSize regionSize) {
    final safe = strength.isNaN ? 0.5 : strength.clamp(0.0, 1.0);
    final shorter = math.min(regionSize.width, regionSize.height);
    final block = (shorter * 0.06 * (0.3 + safe)).round();
    return block.clamp(2, AppConstants.editorMaxPixelateBlock).toInt();
  }

  /// Applies every region in [regions] to [image], in order.
  ///
  /// The image is changed in place and also returned, which is how the
  /// `image` package works elsewhere. A region that lands outside the photo
  /// is skipped rather than throwing, because a drag can end off-screen.
  img.Image applyAll(img.Image image, List<RedactionRegion> regions) {
    if (regions.isEmpty) return image;

    final size = PixelSize(image.width, image.height);
    var result = image;
    for (final region in regions) {
      result = apply(result, region, size);
    }
    return result;
  }

  /// Applies one region to [image].
  img.Image apply(
    img.Image image,
    RedactionRegion region,
    PixelSize imageSize,
  ) {
    final rect = _cropService.toPixelRect(region.rect, imageSize);
    if (rect.width < 1 || rect.height < 1) return image;

    switch (region.mode) {
      case RedactionMode.blackout:
        return _blackout(image, rect, region.colorArgb);
      case RedactionMode.blur:
        return _blur(image, rect, region.strength);
      case RedactionMode.pixelate:
        return _pixelate(image, rect, region.strength);
    }
  }

  img.Image _blackout(img.Image image, PixelRect rect, int colorArgb) {
    return img.fillRect(
      image,
      x1: rect.left,
      y1: rect.top,
      // fillRect treats the second corner as inclusive.
      x2: rect.right - 1,
      y2: rect.bottom - 1,
      color: colorFromArgb(colorArgb),
      alphaBlend: false,
    );
  }

  img.Image _blur(img.Image image, PixelRect rect, double strength) {
    final patch = img.copyCrop(
      image,
      x: rect.left,
      y: rect.top,
      width: rect.width,
      height: rect.height,
    );
    final radius = blurRadiusFor(
      strength,
      PixelSize(patch.width, patch.height),
    );
    final blurred = img.gaussianBlur(patch, radius: radius);
    return img.compositeImage(
      image,
      blurred,
      dstX: rect.left,
      dstY: rect.top,
      blend: img.BlendMode.direct,
    );
  }

  img.Image _pixelate(img.Image image, PixelRect rect, double strength) {
    final patch = img.copyCrop(
      image,
      x: rect.left,
      y: rect.top,
      width: rect.width,
      height: rect.height,
    );
    final block = pixelateBlockFor(
      strength,
      PixelSize(patch.width, patch.height),
    );
    // The average mode is used because the upper-left mode can leak a single
    // sharp pixel of the hidden detail into each block.
    final pixelated = img.pixelate(
      patch,
      size: block,
      mode: img.PixelateMode.average,
    );
    return img.compositeImage(
      image,
      pixelated,
      dstX: rect.left,
      dstY: rect.top,
      blend: img.BlendMode.direct,
    );
  }

  /// Turns a 32 bit ARGB integer into a colour the `image` package accepts.
  static img.Color colorFromArgb(int argb) {
    return img.ColorRgba8(
      (argb >> 16) & 0xFF,
      (argb >> 8) & 0xFF,
      argb & 0xFF,
      (argb >> 24) & 0xFF,
    );
  }
}

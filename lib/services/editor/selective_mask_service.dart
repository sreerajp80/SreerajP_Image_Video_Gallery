import 'dart:math' as math;

import 'package:image/image.dart' as img;
import 'package:in_sreerajp_imgvidgal/models/editor/selective_mask.dart';
import 'package:in_sreerajp_imgvidgal/services/editor/tone_adjustment_service.dart';

/// Computes mask weights and applies localized adjustments for selective
/// gradient and radial masks.
///
/// Each mask defines a region with a soft edge (feather). Pixels inside the
/// region receive the mask's exposure, contrast, temperature, and blur
/// adjustments, blended by how deep inside the region they are.
class SelectiveMaskService {
  final ToneAdjustmentService _toneService;

  const SelectiveMaskService({
    ToneAdjustmentService toneService = const ToneAdjustmentService(),
  }) : _toneService = toneService;

  /// Returns 0.0 (unaffected) to 1.0 (fully affected) for the pixel at
  /// [nx, ny] (both in 0 to 1 normalised coordinates).
  double maskWeight(SelectiveMask mask, double nx, double ny) {
    double raw;

    switch (mask.shape) {
      case MaskShape.linear:
        raw = _linearWeight(mask, nx, ny);
      case MaskShape.radial:
        raw = _radialWeight(mask, nx, ny);
    }

    return mask.invert ? 1 - raw : raw;
  }

  /// Applies every non-neutral mask to [image].
  ///
  /// Each pixel is visited once. For each pixel, all masks contribute their
  /// weight-blended adjustments. The blur is approximated as a desaturation
  /// and contrast reduction, because a true per-pixel Gaussian is too heavy
  /// for real-time preview.
  img.Image applyMasks(img.Image image, List<SelectiveMask> masks) {
    final activeMasks = masks.where((m) => !m.isNeutral).toList();
    if (activeMasks.isEmpty) return image;

    final w = image.width;
    final h = image.height;
    if (w <= 0 || h <= 0) return image;

    for (final pixel in image) {
      final nx = pixel.x / w;
      final ny = pixel.y / h;

      var r = pixel.r.round().clamp(0, 255).toDouble();
      var g = pixel.g.round().clamp(0, 255).toDouble();
      var b = pixel.b.round().clamp(0, 255).toDouble();

      for (final mask in activeMasks) {
        final weight = maskWeight(mask, nx, ny);
        if (weight < 0.001) continue;

        // Exposure: multiply brightness.
        if (mask.exposure != 0) {
          final gain = math.pow(2, mask.exposure).toDouble();
          r = _mix(r, (r * gain).clamp(0.0, 255.0), weight);
          g = _mix(g, (g * gain).clamp(0.0, 255.0), weight);
          b = _mix(b, (b * gain).clamp(0.0, 255.0), weight);
        }

        // Contrast: pivot around mid grey.
        if (mask.contrast != 0) {
          final factor = 1 + mask.contrast;
          r = _mix(r, ((r - 128) * factor + 128).clamp(0.0, 255.0), weight);
          g = _mix(g, ((g - 128) * factor + 128).clamp(0.0, 255.0), weight);
          b = _mix(b, ((b - 128) * factor + 128).clamp(0.0, 255.0), weight);
        }

        // Temperature: warm/cool shift.
        if (mask.temperature != 0) {
          final shift = mask.temperature * 30;
          r = _mix(r, (r + shift).clamp(0.0, 255.0), weight);
          b = _mix(b, (b - shift).clamp(0.0, 255.0), weight);
        }

        // Blur approximation: pull toward grey.
        if (mask.blur > 0) {
          final grey = _toneService.luminance(
            r.round().clamp(0, 255),
            g.round().clamp(0, 255),
            b.round().clamp(0, 255),
          );
          final blurWeight = weight * mask.blur;
          r = _mix(r, grey, blurWeight);
          g = _mix(g, grey, blurWeight);
          b = _mix(b, grey, blurWeight);
        }
      }

      pixel
        ..r = r.round().clamp(0, 255)
        ..g = g.round().clamp(0, 255)
        ..b = b.round().clamp(0, 255);
    }

    return image;
  }

  /// Linear gradient weight: projects the pixel onto the gradient axis.
  double _linearWeight(SelectiveMask mask, double nx, double ny) {
    final sx = mask.startPoint.x;
    final sy = mask.startPoint.y;
    final ex = mask.endPoint.x;
    final ey = mask.endPoint.y;

    final dx = ex - sx;
    final dy = ey - sy;
    final lenSq = dx * dx + dy * dy;
    if (lenSq < 1e-8) return 0;

    // Project the pixel onto the start→end axis.
    final t = ((nx - sx) * dx + (ny - sy) * dy) / lenSq;

    if (t <= 0.0) return 1.0;
    if (t >= 1.0) return 0.0;

    // Blend between a direct linear ramp and a smooth Hermite transition based on feather.
    final linear = 1.0 - t;
    final smooth = 1.0 - t * t * (3 - 2 * t);
    final f = mask.feather.clamp(0.0, 1.0);

    return linear * (1.0 - f) + smooth * f;
  }

  /// Radial gradient weight: distance from the centre.
  double _radialWeight(SelectiveMask mask, double nx, double ny) {
    final cx = mask.startPoint.x;
    final cy = mask.startPoint.y;

    final dx = mask.endPoint.x - cx;
    final dy = mask.endPoint.y - cy;
    final radius = math.sqrt(dx * dx + dy * dy);
    if (radius < 1e-6) return 0;

    final px = nx - cx;
    final py = ny - cy;
    final dist = math.sqrt(px * px + py * py);

    final normalised = dist / radius; // 0 at centre, 1 at edge
    if (normalised >= 1.0) return 0.0;

    final feather = mask.feather.clamp(0.0, 1.0);
    if (feather <= 0.001) return 1.0;

    final inner = 1.0 - feather;
    if (normalised <= inner) return 1.0;

    final u = (normalised - inner) / feather;
    return 1.0 - u * u * (3 - 2 * u);
  }

  double _mix(double from, double to, double amount) =>
      from + (to - from) * amount;
}

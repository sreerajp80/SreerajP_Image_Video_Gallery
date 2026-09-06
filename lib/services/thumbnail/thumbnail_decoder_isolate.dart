import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';

/// Input for the pure Dart thumbnail decode performed in a background isolate.
class ThumbnailDecodeRequest {
  /// Original encoded image bytes.
  final Uint8List bytes;

  /// Longest edge of the produced thumbnail, in pixels.
  final int targetSize;

  /// JPEG quality of the produced thumbnail.
  final int quality;

  const ThumbnailDecodeRequest({
    required this.bytes,
    required this.targetSize,
    this.quality = AppConstants.thumbnailJpegQuality,
  });
}

/// Decodes and downscales [request] to a JPEG thumbnail.
///
/// Top-level so it can run inside an isolate. Returns null for empty or
/// corrupt input; it never throws, because a broken file must only cost the
/// user a placeholder tile.
Uint8List? decodeThumbnailSync(ThumbnailDecodeRequest request) {
  try {
    if (request.bytes.isEmpty || request.targetSize <= 0) return null;

    final decoded = img.decodeImage(request.bytes);
    if (decoded == null) return null;

    // Respect any EXIF orientation flag before resizing.
    final oriented = img.bakeOrientation(decoded);

    final longestEdge = oriented.width >= oriented.height
        ? oriented.width
        : oriented.height;

    final img.Image resized = longestEdge <= request.targetSize
        ? oriented
        : img.copyResize(
            oriented,
            width: oriented.width >= oriented.height
                ? request.targetSize
                : null,
            height: oriented.width >= oriented.height
                ? null
                : request.targetSize,
            interpolation: img.Interpolation.average,
          );

    return img.encodeJpg(resized, quality: request.quality);
  } catch (_) {
    return null;
  }
}

/// Runs [decodeThumbnailSync] on a background isolate so the UI thread is
/// never blocked by image decoding.
Future<Uint8List?> decodeThumbnailInIsolate(
  ThumbnailDecodeRequest request,
) async {
  try {
    return await Isolate.run(() => decodeThumbnailSync(request));
  } catch (_) {
    return null;
  }
}

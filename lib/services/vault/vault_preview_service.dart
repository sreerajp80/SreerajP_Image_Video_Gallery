import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/services/video/video_tools_channel.dart';

/// Builds the small preview shown on a vault tile.
///
/// It cannot use the app's ordinary thumbnail service. That one writes what it
/// makes into the disk cache, which is exactly the leak the vault exists to
/// avoid: a readable copy of a private photo sitting in the cache directory,
/// outliving the vault being locked. Everything here stays in memory and is
/// handed straight to the encryptor.
///
/// A preview that cannot be built is not an error. The tile falls back to an
/// icon, and the item is still safely in the vault — a missing thumbnail is a
/// cosmetic problem, and refusing the import over one would not be.
class VaultPreviewService {
  final VideoToolsChannel _videoTools;

  VaultPreviewService({VideoToolsChannel? videoTools})
    : _videoTools = videoTools ?? VideoToolsChannel();

  /// JPEG preview bytes for [item], or null when none could be made.
  Future<Uint8List?> buildPreview(MediaItem item) async {
    try {
      if (item.mediaType == MediaType.video) {
        return await _videoPreview(item);
      }
      return await _imagePreview(item);
    } catch (_) {
      // Hard rule: never crash on bad input. A corrupt or unusual file loses
      // its preview and keeps everything else.
      return null;
    }
  }

  /// The first frame of a clip, shrunk on the Android side.
  Future<Uint8List?> _videoPreview(MediaItem item) async {
    if (item.path.isEmpty) return null;
    final frame = await _videoTools.grabFrame(
      path: item.path,
      positionMs: 0,
      maxSide: AppConstants.vaultThumbnailSize,
    );
    return frame.isEmpty ? null : frame;
  }

  /// The picture, decoded and shrunk to the preview size.
  ///
  /// Very large originals are skipped rather than decoded: an import of forty
  /// photos should not risk the app being killed for the sake of forty
  /// thumbnails.
  Future<Uint8List?> _imagePreview(MediaItem item) async {
    if (item.path.isEmpty) return null;
    if (item.size <= 0 || item.size > AppConstants.convertMaxSourceBytes) {
      return null;
    }

    final decoded = await img.decodeImageFile(item.path);
    if (decoded == null) return null;

    final longestSide = decoded.width > decoded.height
        ? decoded.width
        : decoded.height;
    final resized = longestSide <= AppConstants.vaultThumbnailSize
        ? decoded
        : img.copyResize(
            decoded,
            width: decoded.width >= decoded.height
                ? AppConstants.vaultThumbnailSize
                : null,
            height: decoded.height > decoded.width
                ? AppConstants.vaultThumbnailSize
                : null,
            interpolation: img.Interpolation.average,
          );

    return Uint8List.fromList(
      img.encodeJpg(resized, quality: AppConstants.vaultThumbnailQuality),
    );
  }
}

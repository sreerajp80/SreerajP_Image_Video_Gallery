import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/services/media/media_store_channel.dart';
import 'package:in_sreerajp_imgvidgal/services/video/video_tools_channel.dart';
import 'package:in_sreerajp_imgvidgal/core/logging/app_logger.dart';

/// Builds the small preview shown on a vault tile.
///
/// It cannot use the app's ordinary thumbnail service. That one writes what it
/// makes into the disk cache, which is exactly the leak the vault exists to
/// avoid: a readable copy of a private photo sitting in the cache directory,
/// outliving the vault being locked. Everything here stays in memory and is
/// handed straight to the encryptor.
///
/// **Where the picture comes from.** A gallery item has a `content://` URI,
/// and the preview comes from MediaStore's own thumbnail call, the one the
/// gallery grid uses. That works on Android 10, where this app may not read
/// shared photos by file path (scoped storage): until 2026-11-25 previews
/// were decoded from the path and every one of them silently failed there.
/// It covers photos and videos, applies the photo's rotation, and runs
/// natively, off the UI thread. An item with no URI (a file received in a
/// phone move, staged in app-private storage, where a path read is allowed)
/// is decoded from its path on a background isolate.
///
/// A preview that cannot be built is not an error. The tile falls back to an
/// icon, and the item is still safely in the vault — a missing thumbnail is a
/// cosmetic problem, and refusing the import over one would not be.
class VaultPreviewService {
  final VideoToolsChannel _videoTools;
  final MediaStoreChannel? _mediaStore;

  VaultPreviewService({
    VideoToolsChannel? videoTools,
    MediaStoreChannel? mediaStore,
  }) : _videoTools = videoTools ?? VideoToolsChannel(),
       _mediaStore = mediaStore;

  /// JPEG preview bytes for [item], or null when none could be made.
  Future<Uint8List?> buildPreview(MediaItem item) async {
    try {
      final fromGallery = await _galleryThumbnail(item);
      if (fromGallery != null) return fromGallery;
      if (item.mediaType == MediaType.video) {
        return await _videoPreview(item);
      }
      return await _imagePreview(item);
    } catch (error) {
      AppLogger.debug('Building a vault preview failed');
      // Hard rule: never crash on bad input. A corrupt or unusual file loses
      // its preview and keeps everything else.
      return null;
    }
  }

  /// MediaStore's thumbnail for a gallery item, or null when it has no URI
  /// or Android has none to give.
  Future<Uint8List?> _galleryThumbnail(MediaItem item) async {
    final mediaStore = _mediaStore;
    final uri = item.uri;
    if (mediaStore == null || uri == null || !uri.startsWith('content://')) {
      return null;
    }
    final bytes = await mediaStore.loadThumbnail(
      uri: uri,
      width: AppConstants.vaultThumbnailSize,
      height: AppConstants.vaultThumbnailSize,
    );
    return bytes == null || bytes.isEmpty ? null : bytes;
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

  /// The picture, decoded and shrunk to the preview size on a background
  /// isolate, so a large photo cannot freeze the screen.
  ///
  /// Very large originals are skipped rather than decoded: an import of forty
  /// photos should not risk the app being killed for the sake of forty
  /// thumbnails.
  Future<Uint8List?> _imagePreview(MediaItem item) async {
    if (item.path.isEmpty) return null;
    if (item.size <= 0 || item.size > AppConstants.convertMaxSourceBytes) {
      return null;
    }
    return _decodeOffThread(item.path);
  }

  // Static, so the closure sent to the isolate holds only the path.
  static Future<Uint8List?> _decodeOffThread(String path) =>
      Isolate.run(() => decodeAndShrink(path));

  /// Decodes the picture at [path] and shrinks its longest side to the
  /// preview size. Public for tests; runs on whatever isolate calls it.
  static Future<Uint8List?> decodeAndShrink(String path) async {
    final decoded = await img.decodeImageFile(path);
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

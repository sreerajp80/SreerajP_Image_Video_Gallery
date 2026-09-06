import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/duplicate/media_hashes.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/media_dao.dart';
import 'package:in_sreerajp_imgvidgal/services/duplicates/hash_tools_channel.dart';
import 'package:in_sreerajp_imgvidgal/services/duplicates/perceptual_hash_service.dart';

/// Loads a small preview of an item, used only as a fallback.
typedef ThumbnailLoader = Future<Uint8List?> Function(MediaItem item);

/// Works out and stores the fingerprints of one media item.
///
/// The real work is done by the platform: Android streams the digest and
/// decodes a downsampled grid, so neither job ever holds a whole file in
/// memory. This class decides what to ask for, turns the grid into the two
/// perceptual hashes, and writes the answers to the database so a later scan
/// does not have to read the file again.
class ContentHashService {
  final HashToolsChannel _channel;
  final MediaDao _mediaDao;
  final PerceptualHashService _perceptualHash;
  final ThumbnailLoader? _thumbnailLoader;

  ContentHashService({
    required HashToolsChannel channel,
    required MediaDao mediaDao,
    PerceptualHashService? perceptualHash,
    ThumbnailLoader? thumbnailLoader,
  }) : _channel = channel,
       _mediaDao = mediaDao,
       _perceptualHash = perceptualHash ?? PerceptualHashService(),
       _thumbnailLoader = thumbnailLoader;

  /// Returns the fingerprints of [item], computing whatever is missing.
  ///
  /// When [stored] already holds everything this item needs, nothing is read
  /// and the stored value comes straight back. That is what makes a second
  /// duplicate scan almost instant.
  ///
  /// Nothing here throws. A file that cannot be read gives back whatever was
  /// worked out, possibly nothing at all, because a scan across thousands of
  /// files will always meet a few broken ones and must keep going.
  Future<MediaHashes> computeFor(
    MediaItem item, {
    MediaHashes? stored,
    bool persist = true,
  }) async {
    final needsPerceptual = _needsPerceptualHash(item);
    final existing =
        stored ??
        MediaHashes.fromColumns(
          mediaId: item.id,
          sha256: item.sha256Hash,
          storedPerceptual: item.pHash,
        );

    final hasDigest = existing.sha256 != null;
    final hasPerceptual = !needsPerceptual || existing.hasPerceptual;
    if (hasDigest && hasPerceptual) return existing;

    final uri = item.uri;
    var digest = existing.sha256;
    var perceptual = existing.pHash;
    var difference = existing.dHash;

    if (!hasDigest &&
        uri != null &&
        uri.isNotEmpty &&
        item.size <= AppConstants.duplicateMaxHashableBytes) {
      digest = await _safeDigest(uri);
    }

    if (needsPerceptual && !existing.hasPerceptual) {
      final grid = await _grayscaleGrid(item);
      if (grid != null) {
        try {
          perceptual = _perceptualHash.computePHash(grid);
          difference = _perceptualHash.computeDHash(grid);
        } catch (_) {
          // A grid of the wrong length means the decode went wrong; the item
          // simply has no perceptual hash.
          perceptual = null;
          difference = null;
        }
      }
    }

    final result = MediaHashes(
      mediaId: item.id,
      sha256: digest,
      pHash: perceptual,
      dHash: difference,
    );

    if (persist && result.hasAny && result != existing) {
      await _persist(result);
    }
    return result;
  }

  /// Writes the fingerprints to the media row, ignoring a write failure.
  Future<void> _persist(MediaHashes hashes) async {
    try {
      await _mediaDao.updateHashes(
        hashes.mediaId,
        sha256: hashes.sha256,
        pHash: hashes.encodedPerceptual,
      );
    } catch (_) {
      // The hash is a cache. Failing to save it costs time on the next scan
      // and nothing else, so it must not end this one.
    }
  }

  /// Only still pictures get a perceptual hash.
  ///
  /// A video would need frames pulled and compared, which is a different job
  /// with a different cost, so videos are matched on their bytes alone.
  bool _needsPerceptualHash(MediaItem item) {
    return item.mediaType == MediaType.image ||
        item.mediaType == MediaType.rawImage ||
        item.mediaType == MediaType.gif;
  }

  Future<String?> _safeDigest(String uri) async {
    try {
      final digest = await _channel.sha256(uri);
      if (digest == null || digest.isEmpty) return null;
      return digest.toLowerCase();
    } catch (_) {
      return null;
    }
  }

  /// The grayscale grid for [item], from the platform or from a thumbnail.
  ///
  /// The platform path is the one that matters: it downsamples while it
  /// decodes, so a huge photo costs almost nothing. The thumbnail path exists
  /// for when the channel is not there at all, and works from bytes that have
  /// already been shrunk, so it is cheap too.
  Future<Uint8List?> _grayscaleGrid(MediaItem item) async {
    final size = _perceptualHash.gridSize;
    final uri = item.uri;

    if (uri != null && uri.isNotEmpty) {
      try {
        final grid = await _channel.grayscale(uri, size: size);
        if (grid != null) return grid;
      } catch (_) {
        // Fall through to the thumbnail.
      }
    }

    final loader = _thumbnailLoader;
    if (loader == null) return null;
    try {
      final bytes = await loader(item);
      if (bytes == null || bytes.isEmpty) return null;
      return grayscaleFromEncodedImage(bytes, size);
    } catch (_) {
      return null;
    }
  }

  /// Decodes [bytes] and reduces them to a [size] by [size] grayscale grid.
  ///
  /// Exposed so it can be tested directly. Returns null when the bytes are
  /// not a picture this build can decode, which a corrupt file often is not.
  static Uint8List? grayscaleFromEncodedImage(Uint8List bytes, int size) {
    img.Image? decoded;
    try {
      decoded = img.decodeImage(bytes);
    } catch (_) {
      return null;
    }
    if (decoded == null || decoded.width <= 0 || decoded.height <= 0) {
      return null;
    }

    final resized = img.copyResize(
      decoded,
      width: size,
      height: size,
      interpolation: img.Interpolation.average,
    );

    final grid = Uint8List(size * size);
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        final pixel = resized.getPixel(x, y);
        // Rec. 601 luma, the same weighting Android's own grayscale uses, so
        // the two paths produce comparable hashes.
        final luma = 0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b;
        grid[y * size + x] = luma.round().clamp(0, 255);
      }
    }
    return grid;
  }
}

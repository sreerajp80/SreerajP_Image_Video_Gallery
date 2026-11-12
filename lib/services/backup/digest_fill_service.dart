import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/media_dao.dart';
import 'package:in_sreerajp_imgvidgal/services/duplicates/hash_tools_channel.dart';
import 'package:in_sreerajp_imgvidgal/core/logging/app_logger.dart';

/// Works out the SHA-256 of files that do not have one yet, and saves it.
///
/// A SHA-256 is the only way to recognise the same photo on another phone
/// whatever its folder, name or date. Many photos never get one, because only
/// the duplicate scan computes it. This fills that gap where it matters:
///
/// * **Before a backup or a QR send**, for the photos that carry the user's
///   data, so the archive can be matched on another phone.
/// * **During a restore**, for the photos on this phone whose *size* equals
///   that of a record nothing else matched. Same size is cheap to check and
///   narrows thousands of photos to a handful worth hashing.
///
/// Android streams each file through the digest, so even a large video never
/// sits in memory. Nothing here throws: an unreadable file is simply left
/// without a digest.
class DigestFillService {
  final MediaDao _mediaDao;
  final HashToolsChannel _channel;

  DigestFillService({
    required MediaDao mediaDao,
    required HashToolsChannel channel,
  }) : _mediaDao = mediaDao,
       _channel = channel;

  /// Computes and saves the digest of each item in [ids] that has none.
  ///
  /// Returns how many digests were added. [onProgress] gets (done, total).
  Future<int> fillMissing(
    Iterable<String> ids, {
    void Function(int done, int total)? onProgress,
  }) async {
    final wanted = ids.toSet().toList();
    if (wanted.isEmpty) return 0;

    List<MediaItem> items;
    try {
      items = await _mediaDao.getMediaItemsByIds(wanted);
    } catch (error) {
      AppLogger.warning('Reading items to fingerprint failed', error: error);
      return 0;
    }

    final missing = items.where(_needsDigest).toList();
    var added = 0;
    for (var i = 0; i < missing.length; i++) {
      if (await _digestAndSave(missing[i]) != null) added++;
      onProgress?.call(i + 1, missing.length);
    }
    return added;
  }

  /// Gives a digest to every item in [local] whose size is in [sizes] and
  /// which has none yet, and returns [local] with those digests filled in.
  ///
  /// The order of [local] is kept. Items that were not hashed come back as
  /// they were.
  Future<List<MediaItem>> fillBySize(
    List<MediaItem> local,
    Set<int> sizes, {
    void Function(int done, int total)? onProgress,
  }) async {
    if (sizes.isEmpty) return local;

    final targets = <int>[
      for (var i = 0; i < local.length; i++)
        if (sizes.contains(local[i].size) && _needsDigest(local[i])) i,
    ];
    if (targets.isEmpty) return local;

    final out = List<MediaItem>.from(local);
    for (var n = 0; n < targets.length; n++) {
      final index = targets[n];
      final digest = await _digestAndSave(out[index]);
      if (digest != null) out[index] = out[index].copyWith(sha256Hash: digest);
      onProgress?.call(n + 1, targets.length);
    }
    return out;
  }

  static bool _needsDigest(MediaItem item) {
    final known = item.sha256Hash;
    final uri = item.uri;
    return (known == null || known.isEmpty) &&
        uri != null &&
        uri.isNotEmpty &&
        item.size > 0 &&
        item.size <= AppConstants.duplicateMaxHashableBytes;
  }

  Future<String?> _digestAndSave(MediaItem item) async {
    try {
      final raw = await _channel.sha256(item.uri!);
      if (raw == null || raw.isEmpty) return null;
      final digest = raw.toLowerCase();
      await _mediaDao.updateHashes(item.id, sha256: digest);
      return digest;
    } catch (error) {
      AppLogger.debug('Fingerprinting one file failed');
      // Safe to ignore: this file is matched by name, size and date instead.
      return null;
    }
  }
}

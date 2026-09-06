import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:path/path.dart' as p;

/// Stores generated thumbnails as JPEG files in the app cache directory.
///
/// Layout: `<root>/<size>/<hash>.jpg`, where the hash covers the media id, its
/// last modification time, and its byte size. An edited or replaced file
/// therefore produces a new key and its stale thumbnail is simply never read.
///
/// Nothing here is fatal: any I/O failure degrades to a cache miss, because a
/// missing thumbnail must never break the gallery.
class ThumbnailDiskCache {
  /// Root folder holding all cached thumbnails.
  final Directory rootDirectory;

  /// Maximum total bytes kept on disk before eviction runs.
  final int maxBytes;

  ThumbnailDiskCache({required this.rootDirectory, required this.maxBytes});

  /// Builds the stable cache key for an item at a given thumbnail size.
  static String buildKey(MediaItem item, int size) {
    final raw =
        '${item.id}|'
        '${item.dateModified.millisecondsSinceEpoch}|'
        '${item.size}|'
        '$size';
    return sha1.convert(raw.codeUnits).toString();
  }

  /// The file that would hold this key's thumbnail.
  File fileFor(String key, int size) {
    return File(p.join(rootDirectory.path, '$size', '$key.jpg'));
  }

  /// Reads cached bytes, or null on a miss or any read failure.
  Future<Uint8List?> read(String key, int size) async {
    try {
      final file = fileFor(key, size);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return null;
      // Touch the file so least-recently-used eviction keeps hot entries.
      await _touch(file);
      return bytes;
    } catch (_) {
      return null;
    }
  }

  /// Writes bytes for [key], then enforces the byte budget.
  ///
  /// Returns true when the write succeeded.
  Future<bool> write(String key, int size, Uint8List bytes) async {
    if (bytes.isEmpty) return false;
    try {
      final file = fileFor(key, size);
      await file.parent.create(recursive: true);

      // Write to a staging file first so a crash cannot leave a half thumbnail.
      final staging = File('${file.path}.tmp');
      await staging.writeAsBytes(bytes, flush: true);
      await staging.rename(file.path);

      await evictIfOverBudget();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Total bytes currently stored.
  Future<int> currentBytes() async {
    var total = 0;
    for (final file in await _cachedFiles()) {
      try {
        total += await file.length();
      } catch (_) {
        // Ignore files that vanished mid-scan.
      }
    }
    return total;
  }

  /// Deletes the oldest thumbnails until the cache fits inside [maxBytes].
  Future<int> evictIfOverBudget() async {
    try {
      final files = await _cachedFiles();
      if (files.isEmpty) return 0;

      final stats = <_CacheEntry>[];
      var total = 0;
      for (final file in files) {
        try {
          final stat = await file.stat();
          total += stat.size;
          stats.add(_CacheEntry(file, stat.modified, stat.size));
        } catch (_) {
          continue;
        }
      }
      if (total <= maxBytes) return 0;

      stats.sort((a, b) => a.modified.compareTo(b.modified));

      var removed = 0;
      for (final entry in stats) {
        if (total <= maxBytes) break;
        try {
          await entry.file.delete();
          total -= entry.size;
          removed++;
        } catch (_) {
          continue;
        }
      }
      return removed;
    } catch (_) {
      return 0;
    }
  }

  /// Deletes every cached thumbnail.
  Future<void> clear() async {
    try {
      if (await rootDirectory.exists()) {
        await rootDirectory.delete(recursive: true);
      }
    } catch (_) {
      // Clearing the cache is best effort only.
    }
  }

  Future<List<File>> _cachedFiles() async {
    try {
      if (!await rootDirectory.exists()) return const <File>[];
      final entities = await rootDirectory.list(recursive: true).toList();
      return entities
          .whereType<File>()
          .where((file) => p.extension(file.path) == '.jpg')
          .toList(growable: false);
    } catch (_) {
      return const <File>[];
    }
  }

  Future<void> _touch(File file) async {
    try {
      await file.setLastModified(DateTime.now());
    } catch (_) {
      // Not all filesystems allow this; recency then falls back to write time.
    }
  }

  /// Default cache root: `<appCacheDir>/thumbnails`.
  static Directory defaultRoot(Directory appCacheDirectory) {
    return Directory(
      p.join(appCacheDirectory.path, AppConstants.thumbnailCacheDirectoryName),
    );
  }
}

class _CacheEntry {
  final File file;
  final DateTime modified;
  final int size;

  const _CacheEntry(this.file, this.modified, this.size);
}

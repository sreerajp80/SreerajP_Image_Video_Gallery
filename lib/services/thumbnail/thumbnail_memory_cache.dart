import 'dart:collection';
import 'dart:typed_data';

/// Least-recently-used cache of encoded thumbnail bytes held in RAM.
///
/// Bounded by both entry count and total bytes, whichever is reached first.
/// Pure Dart with no Flutter or platform dependency, so it is fully testable.
class ThumbnailMemoryCache {
  final int maxItems;
  final int maxBytes;

  /// Insertion-ordered map; the first key is the least recently used.
  final LinkedHashMap<String, Uint8List> _entries =
      LinkedHashMap<String, Uint8List>();

  int _currentBytes = 0;

  ThumbnailMemoryCache({required this.maxItems, required this.maxBytes})
    : assert(maxItems > 0, 'maxItems must be positive'),
      assert(maxBytes > 0, 'maxBytes must be positive');

  /// Number of cached thumbnails.
  int get length => _entries.length;

  /// Total bytes currently held.
  int get currentBytes => _currentBytes;

  /// Cache keys ordered from least to most recently used.
  Iterable<String> get keysByAge => List<String>.unmodifiable(_entries.keys);

  /// Returns cached bytes for [key] and marks it as most recently used.
  Uint8List? get(String key) {
    final value = _entries.remove(key);
    if (value == null) return null;
    _entries[key] = value;
    return value;
  }

  /// Whether [key] is currently cached. Does not change recency.
  bool containsKey(String key) => _entries.containsKey(key);

  /// Stores [bytes] under [key], evicting the oldest entries as needed.
  ///
  /// A single item larger than [maxBytes] is not cached at all, so one huge
  /// thumbnail cannot flush the whole cache.
  void put(String key, Uint8List bytes) {
    final existing = _entries.remove(key);
    if (existing != null) {
      _currentBytes -= existing.lengthInBytes;
    }

    if (bytes.lengthInBytes > maxBytes) return;

    _entries[key] = bytes;
    _currentBytes += bytes.lengthInBytes;
    _evictIfNeeded();
  }

  /// Removes one entry.
  void remove(String key) {
    final removed = _entries.remove(key);
    if (removed != null) {
      _currentBytes -= removed.lengthInBytes;
    }
  }

  /// Empties the cache.
  void clear() {
    _entries.clear();
    _currentBytes = 0;
  }

  void _evictIfNeeded() {
    while (_entries.isNotEmpty &&
        (_entries.length > maxItems || _currentBytes > maxBytes)) {
      final oldestKey = _entries.keys.first;
      final removed = _entries.remove(oldestKey);
      if (removed != null) {
        _currentBytes -= removed.lengthInBytes;
      }
    }
  }
}

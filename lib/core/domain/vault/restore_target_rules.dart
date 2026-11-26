import 'package:path/path.dart' as p;

/// Where a restored vault item goes in the shared gallery (Android 10+).
///
/// Pure, so it is unit tested without a device. Android checks the same
/// rule again before writing (`MediaStoreWriter.isAllowedRelativePath`),
/// because the path comes from a stored record.
///
/// MediaStore only lets a photo into `DCIM/…` or `Pictures/…`, and a video
/// into `DCIM/…`, `Movies/…` or `Pictures/…`. The item goes back to its
/// original folder when that folder is one of those (re-created if it is
/// gone), and to [fallback] otherwise.
class RestoreTargetRules {
  const RestoreTargetRules._();

  /// Where an item goes when its own folder cannot be used.
  static const String fallback = 'Pictures/Drishya Restored';

  /// How deep a kept folder may be.
  static const int maxLevels = 4;

  static const List<String> _storageRoots = <String>[
    '/storage/emulated/0/',
    '/sdcard/',
  ];

  static const Set<String> _photoRoots = <String>{'DCIM', 'Pictures'};
  static const Set<String> _videoRoots = <String>{'DCIM', 'Movies', 'Pictures'};

  static final RegExp _badCharacters = RegExp(r'[\x00-\x1F\x7F\\:*?"<>|]');

  /// The MediaStore relative folder for an item first stored at
  /// [originalPath], e.g. `DCIM/Camera`.
  static String relativePathFor(String originalPath, {required bool isVideo}) {
    if (originalPath.isEmpty) return fallback;
    final folder = p.posix.dirname(originalPath);
    for (final root in _storageRoots) {
      if (folder.startsWith(root)) {
        final relative = folder.substring(root.length);
        return isAllowed(relative, isVideo: isVideo) ? relative : fallback;
      }
    }
    return fallback;
  }

  /// Whether MediaStore takes this kind of file in [relativePath].
  static bool isAllowed(String relativePath, {required bool isVideo}) {
    final parts = relativePath.split('/');
    if (parts.isEmpty || parts.length > maxLevels) return false;
    final roots = isVideo ? _videoRoots : _photoRoots;
    if (!roots.contains(parts.first)) return false;
    for (final part in parts) {
      if (part.isEmpty || part.length > 100) return false;
      if (part.startsWith('.')) return false;
      if (_badCharacters.hasMatch(part)) return false;
    }
    return true;
  }
}

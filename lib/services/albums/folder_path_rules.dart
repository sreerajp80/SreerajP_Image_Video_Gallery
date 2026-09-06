/// Pure path handling for device folder albums.
///
/// A folder album is not stored anywhere: it is simply every indexed item whose
/// parent directory is the same. That makes the split between "directory" and
/// "file name" the whole basis of the feature, so it lives here on its own,
/// with no database and no file system behind it.
class FolderPathRules {
  const FolderPathRules._();

  /// Separator used by Android paths, and the only one the SQL side sees.
  ///
  /// The Dart side also tolerates a backslash so a test may build a
  /// Windows-style path, but nothing the device records ever uses one.
  static const String separator = '/';

  /// Character used to escape SQL `LIKE` wildcards.
  ///
  /// A backslash would be a poor choice: it is data inside a Windows-style
  /// path, and a character that is both data and escape in one string is
  /// exactly the confusion worth avoiding.
  static const String likeEscape = '!';

  /// Returns the parent directory of [path], without a trailing separator.
  ///
  /// A path with no separator at all has no parent, so this returns an empty
  /// string rather than guessing one.
  static String parentDirectory(String path) {
    final trimmed = stripTrailingSeparators(path);
    final index = _lastSeparatorIndex(trimmed);
    if (index < 0) return '';
    // A file directly under the root keeps the root's own separator, otherwise
    // "/a.jpg" would report an empty parent and fall in with unrooted names.
    if (index == 0) return trimmed.substring(0, 1);
    return trimmed.substring(0, index);
  }

  /// The name shown for a folder: its last path segment.
  ///
  /// Falls back to the whole path when there is no segment to take, so a folder
  /// always has something to draw rather than an empty label.
  static String displayName(String directory) {
    final trimmed = stripTrailingSeparators(directory);
    if (trimmed.isEmpty) return directory;
    final index = _lastSeparatorIndex(trimmed);
    if (index < 0) return trimmed;
    final name = trimmed.substring(index + 1);
    return name.isEmpty ? trimmed : name;
  }

  /// Builds the `LIKE` pattern matching every path that starts inside
  /// [directory], including paths further down in sub-folders.
  ///
  /// The database pairs this with a "no further separator" test to get an exact
  /// parent match. The pattern alone is the part an index can use, which is why
  /// the two halves are separate.
  ///
  /// The wildcards in the directory name itself are escaped first: without
  /// that, a real folder called `100%` would match far more than itself,
  /// because `%` means "anything" to `LIKE`.
  static String childLikePattern(String directory) {
    final base = stripTrailingSeparators(directory);
    // The root is already its own separator, so appending another would ask
    // for "//".
    final prefix = base == separator ? base : '$base$separator';
    return '${escapeLike(prefix)}%';
  }

  /// How many characters of a path the [childLikePattern] prefix covers.
  ///
  /// The database uses this to look at only the part of the path after the
  /// directory, where a remaining separator means the file is in a sub-folder
  /// rather than in this folder itself.
  static int childPrefixLength(String directory) {
    final base = stripTrailingSeparators(directory);
    return base == separator ? 1 : base.length + 1;
  }

  /// Escapes the three characters `LIKE` treats specially.
  ///
  /// The escape character has to be handled first; doing it later would also
  /// escape the markers this method has just added.
  static String escapeLike(String value) {
    return value
        .replaceAll(likeEscape, '$likeEscape$likeEscape')
        .replaceAll('%', '$likeEscape%')
        .replaceAll('_', '${likeEscape}_');
  }

  /// Whether [path] sits directly inside [directory].
  ///
  /// This is the rule the database query reproduces, kept here so both sides
  /// can be tested against the same definition.
  static bool isDirectlyInside(String path, String directory) {
    return parentDirectory(path) == stripTrailingSeparators(directory);
  }

  /// Removes trailing separators but never the whole string, so the root path
  /// "/" survives as "/" rather than becoming empty.
  static String stripTrailingSeparators(String value) {
    var end = value.length;
    while (end > 1 && _isSeparator(value[end - 1])) {
      end--;
    }
    return value.substring(0, end);
  }

  static bool _isSeparator(String char) => char == '/' || char == r'\';

  static int _lastSeparatorIndex(String value) {
    final forward = value.lastIndexOf('/');
    final back = value.lastIndexOf(r'\');
    return forward > back ? forward : back;
  }
}

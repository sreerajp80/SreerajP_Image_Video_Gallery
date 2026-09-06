/// Why an album name was refused.
enum AlbumNameError { empty, tooLong, duplicate }

/// The outcome of checking one album name.
class AlbumNameCheck {
  /// The name after trimming and collapsing inner whitespace.
  final String normalized;

  /// Why the name was refused, or null when it is fine.
  final AlbumNameError? error;

  const AlbumNameCheck(this.normalized, this.error);

  bool get isValid => error == null;
}

/// The rules every album name must pass, in one pure place.
///
/// This mirrors `TagNameRules` on purpose. A user who has learned how tag names
/// behave should not have to learn a second set of rules for albums.
class AlbumNameRules {
  const AlbumNameRules._();

  /// Longest album name allowed.
  static const int maxLength = 60;

  /// Trims the ends and squeezes runs of whitespace down to one space.
  ///
  /// Without this, "Trip  2026" and "Trip 2026" would be two different albums
  /// that look identical in the list.
  static String normalize(String name) {
    return name.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Checks [name] against every rule.
  ///
  /// [existingNames] are the names already in use. [ignoreName] is the album's
  /// own current name, so renaming an album to the same text is not treated as
  /// a clash with itself.
  static AlbumNameCheck check(
    String name, {
    Iterable<String> existingNames = const <String>[],
    String? ignoreName,
  }) {
    final normalized = normalize(name);

    if (normalized.isEmpty) {
      return AlbumNameCheck(normalized, AlbumNameError.empty);
    }
    if (normalized.length > maxLength) {
      return AlbumNameCheck(normalized, AlbumNameError.tooLong);
    }

    final ignore = ignoreName == null ? null : normalize(ignoreName);
    final lower = normalized.toLowerCase();
    for (final existing in existingNames) {
      final other = normalize(existing);
      if (ignore != null && other.toLowerCase() == ignore.toLowerCase()) {
        continue;
      }
      if (other.toLowerCase() == lower) {
        return AlbumNameCheck(normalized, AlbumNameError.duplicate);
      }
    }

    return AlbumNameCheck(normalized, null);
  }
}

/// The note attached to one media item.
///
/// The text is stored in the media table's `user_notes` column, which the
/// search index already covers, so a note becomes searchable the moment it is
/// saved without anything extra being written.
class MediaNote {
  /// The media item this belongs to.
  final String mediaId;

  /// The markdown source, exactly as the user typed it.
  final String markdown;

  /// When it was last written, or null if it has never been saved.
  final DateTime? updatedAt;

  const MediaNote({required this.mediaId, this.markdown = '', this.updatedAt});

  /// Whether there is anything worth showing or saving.
  bool get isEmpty => markdown.trim().isEmpty;

  /// Whether there is a note.
  bool get isNotEmpty => !isEmpty;

  /// The first non-empty line, with markers left in.
  ///
  /// The details sheet shows this so a photo with a note says so without the
  /// whole note being rendered behind it.
  String get firstLine {
    for (final line in markdown.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return '';
  }

  MediaNote copyWith({String? mediaId, String? markdown, DateTime? updatedAt}) {
    return MediaNote(
      mediaId: mediaId ?? this.mediaId,
      markdown: markdown ?? this.markdown,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MediaNote &&
        other.mediaId == mediaId &&
        other.markdown == markdown &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(mediaId, markdown, updatedAt);

  /// Names the item and the length only.
  ///
  /// A note is private writing about a private photo, so it never goes into a
  /// log line, not even in a debug build.
  @override
  String toString() => 'MediaNote($mediaId, ${markdown.length} chars)';
}

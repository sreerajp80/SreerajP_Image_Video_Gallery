import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/notes/media_note.dart';
import 'package:in_sreerajp_imgvidgal/repositories/media_repository.dart';

/// Thrown when a note cannot be saved.
class NotesException implements Exception {
  final String message;

  const NotesException(this.message);

  @override
  String toString() => 'NotesException: $message';
}

/// Reads and writes the note attached to a media item.
///
/// The note lives in the media row's `user_notes` column, which a database
/// trigger mirrors into the search index, so writing a note is all it takes to
/// make it findable.
///
/// Nothing here logs the note's text. A note about a private photo is private
/// writing, and a debug log is still a log.
class MediaNotesService {
  final MediaRepository _repository;

  /// Longest note that will be stored.
  final int maxLength;

  const MediaNotesService({
    required MediaRepository repository,
    this.maxLength = AppConstants.notesMaxLength,
  }) : _repository = repository;

  /// Reads the note for [mediaId].
  ///
  /// An item with no note gives an empty note rather than null, so the editor
  /// has something to open either way.
  Future<MediaNote> read(String mediaId) async {
    final item = await _repository.getMediaItemById(mediaId);
    return MediaNote(mediaId: mediaId, markdown: item?.userNotes ?? '');
  }

  /// Saves [markdown] as the note for [mediaId].
  ///
  /// A note that is only whitespace clears the note rather than storing blank
  /// text, so a photo does not end up marked as annotated with nothing in it.
  Future<MediaNote> save(String mediaId, String markdown) async {
    if (mediaId.isEmpty) {
      throw const NotesException('There is no item to write a note about');
    }
    if (markdown.length > maxLength) {
      throw NotesException('A note can be at most $maxLength characters long');
    }

    final trimmed = markdown.trim();
    await _repository.setUserNotes(mediaId, trimmed.isEmpty ? null : trimmed);

    return MediaNote(
      mediaId: mediaId,
      markdown: trimmed,
      updatedAt: DateTime.now(),
    );
  }

  /// Adds [text] to the end of the existing note.
  ///
  /// Used by the scanner and the text extractor, which both offer to keep what
  /// they found. Appending rather than replacing matters: someone who has
  /// already written about a photo should not lose it by tapping "save to
  /// notes" on a QR code.
  Future<MediaNote> append(String mediaId, String text) async {
    final addition = text.trim();
    if (addition.isEmpty) return read(mediaId);

    final existing = await read(mediaId);
    final combined = existing.isEmpty
        ? addition
        : '${existing.markdown.trimRight()}\n\n$addition';

    // Appending is the one path where the user did not type the text, so a cap
    // reached here trims rather than refuses: losing the tail of a long block
    // of scanned text is better than the save failing outright.
    final capped = combined.length > maxLength
        ? combined.substring(0, maxLength)
        : combined;

    return save(mediaId, capped);
  }

  /// Removes the note entirely.
  Future<void> clear(String mediaId) {
    return _repository.setUserNotes(mediaId, null);
  }
}

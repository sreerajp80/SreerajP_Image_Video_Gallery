import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/models/notes/media_note.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/services/notes/markdown_parser.dart';
import 'package:in_sreerajp_imgvidgal/services/notes/media_notes_service.dart';

/// Reads note text into blocks the view can draw.
final markdownParserProvider = Provider<MarkdownParser>((ref) {
  return const MarkdownParser();
});

/// Reads and writes the note on a media item.
final mediaNotesServiceProvider = Provider<MediaNotesService>((ref) {
  return MediaNotesService(repository: ref.watch(mediaRepositoryProvider));
});

/// The note on one item, as it currently stands in the database.
final mediaNoteProvider = FutureProvider.family<MediaNote, String>((
  ref,
  mediaId,
) {
  return ref.watch(mediaNotesServiceProvider).read(mediaId);
});

/// Writes the note for one item.
class NotesController extends StateNotifier<AsyncValue<MediaNote?>> {
  final Ref _ref;

  NotesController(this._ref) : super(const AsyncValue.data(null));

  /// Saves [markdown] as the note on [mediaId].
  Future<bool> save(String mediaId, String markdown) async {
    state = const AsyncValue.loading();

    try {
      final note = await _ref
          .read(mediaNotesServiceProvider)
          .save(mediaId, markdown);

      state = AsyncValue.data(note);
      // The details sheet and anything else showing the note read it through
      // the family provider, so it is refreshed rather than left stale.
      _ref.invalidate(mediaNoteProvider(mediaId));
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  /// Adds [text] to the end of the note, keeping what is already written.
  ///
  /// This is the path the scanner and the text reader use, and appending
  /// rather than replacing is the whole point: nobody should lose what they
  /// wrote by saving a scanned code onto the same photo.
  Future<bool> append(String mediaId, String text) async {
    state = const AsyncValue.loading();

    try {
      final note = await _ref
          .read(mediaNotesServiceProvider)
          .append(mediaId, text);

      state = AsyncValue.data(note);
      _ref.invalidate(mediaNoteProvider(mediaId));
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  /// Removes the note.
  Future<bool> clear(String mediaId) async {
    try {
      await _ref.read(mediaNotesServiceProvider).clear(mediaId);
      state = AsyncValue.data(MediaNote(mediaId: mediaId));
      _ref.invalidate(mediaNoteProvider(mediaId));
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }
}

final notesControllerProvider =
    StateNotifierProvider<NotesController, AsyncValue<MediaNote?>>((ref) {
      return NotesController(ref);
    });

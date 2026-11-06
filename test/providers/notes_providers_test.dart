import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/notes/media_note.dart';
import 'package:in_sreerajp_imgvidgal/providers/notes_providers.dart';
import 'package:in_sreerajp_imgvidgal/services/notes/media_notes_service.dart';

/// Keeps notes in a map, and can be told to fail.
class _FakeNotesService implements MediaNotesService {
  final Map<String, String> notes = <String, String>{};
  bool fail = false;
  int reads = 0;

  @override
  int get maxLength => 10000;

  void _check() {
    if (fail) throw StateError('disk full');
  }

  @override
  Future<MediaNote> read(String mediaId) async {
    reads++;
    return MediaNote(mediaId: mediaId, markdown: notes[mediaId] ?? '');
  }

  @override
  Future<MediaNote> save(String mediaId, String markdown) async {
    _check();
    notes[mediaId] = markdown;
    return MediaNote(mediaId: mediaId, markdown: markdown);
  }

  @override
  Future<MediaNote> append(String mediaId, String text) async {
    _check();
    final joined = [notes[mediaId], text].whereType<String>().join('\n');
    notes[mediaId] = joined;
    return MediaNote(mediaId: mediaId, markdown: joined);
  }

  @override
  Future<void> clear(String mediaId) async {
    _check();
    notes.remove(mediaId);
  }
}

void main() {
  late _FakeNotesService service;
  late ProviderContainer container;

  setUp(() {
    service = _FakeNotesService();
    container = ProviderContainer(
      overrides: <Override>[
        mediaNotesServiceProvider.overrideWithValue(service),
      ],
    );
  });

  tearDown(() => container.dispose());

  NotesController controller() =>
      container.read(notesControllerProvider.notifier);

  test('save stores the note and refreshes the family provider', () async {
    container.listen(mediaNoteProvider('m1'), (_, _) {});
    await container.read(mediaNoteProvider('m1').future);
    final readsBefore = service.reads;

    expect(await controller().save('m1', '# Trip'), isTrue);

    expect(container.read(notesControllerProvider).value!.markdown, '# Trip');
    final fresh = await container.read(mediaNoteProvider('m1').future);
    expect(fresh.markdown, '# Trip');
    expect(service.reads, greaterThan(readsBefore));
  });

  test('append adds to what is there', () async {
    await controller().save('m1', 'one');
    await controller().append('m1', 'two');

    expect(container.read(notesControllerProvider).value!.markdown, 'one\ntwo');
  });

  test('clear leaves an empty note', () async {
    await controller().save('m1', 'one');
    expect(await controller().clear('m1'), isTrue);

    final note = container.read(notesControllerProvider).value!;
    expect(note.mediaId, 'm1');
    expect(note.markdown, isEmpty);
  });

  test('a failed save reports false and an error state', () async {
    service.fail = true;

    expect(await controller().save('m1', 'x'), isFalse);
    expect(container.read(notesControllerProvider).hasError, isTrue);
  });

  test('a failed append or clear reports false', () async {
    service.fail = true;

    expect(await controller().append('m1', 'x'), isFalse);
    expect(await controller().clear('m1'), isFalse);
  });
}

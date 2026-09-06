import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/notes/markdown_block.dart';
import 'package:in_sreerajp_imgvidgal/models/notes/markdown_span.dart';
import 'package:in_sreerajp_imgvidgal/models/notes/media_note.dart';

void main() {
  group('MediaNote', () {
    test('a note of only blank space counts as empty', () {
      const note = MediaNote(mediaId: '1', markdown: '   \n  ');
      expect(note.isEmpty, isTrue);
      expect(note.isNotEmpty, isFalse);
    });

    test('a written note is not empty', () {
      const note = MediaNote(mediaId: '1', markdown: 'something');
      expect(note.isNotEmpty, isTrue);
    });

    test('the first line skips leading blank lines', () {
      const note = MediaNote(mediaId: '1', markdown: '\n\n  # Title\nbody');
      expect(note.firstLine, '# Title');
    });

    test('an empty note has no first line', () {
      expect(const MediaNote(mediaId: '1').firstLine, '');
    });

    test('equality covers the text and the time', () {
      final time = DateTime(2026, 8, 31);
      final note = MediaNote(mediaId: '1', markdown: 'a', updatedAt: time);

      expect(note, MediaNote(mediaId: '1', markdown: 'a', updatedAt: time));
      expect(note, isNot(note.copyWith(markdown: 'b')));
    });

    // A note is private writing about a private photo.
    test('toString never prints the note text', () {
      const note = MediaNote(mediaId: '1', markdown: 'my bank pin is 1234');
      expect(note.toString(), isNot(contains('1234')));
      expect(note.toString(), contains('19 chars'));
    });
  });

  group('MarkdownSpan', () {
    test('a plain span carries no target', () {
      const span = MarkdownSpan('text');
      expect(span.style, MarkdownSpanStyle.plain);
      expect(span.target, isEmpty);
    });

    test('a link carries its label and target apart', () {
      const span = MarkdownSpan.link('label', 'https://example.com');
      expect(span.style, MarkdownSpanStyle.link);
      expect(span.text, 'label');
      expect(span.target, 'https://example.com');
    });

    test('equality covers the style', () {
      expect(
        const MarkdownSpan('a', style: MarkdownSpanStyle.bold),
        isNot(const MarkdownSpan('a', style: MarkdownSpanStyle.italic)),
      );
    });
  });

  group('MarkdownBlock', () {
    const block = MarkdownBlock(
      type: MarkdownBlockType.paragraph,
      spans: <MarkdownSpan>[
        MarkdownSpan('one '),
        MarkdownSpan('two', style: MarkdownSpanStyle.bold),
      ],
    );

    test('plain text joins the spans with no markers', () {
      expect(block.plainText, 'one two');
    });

    test('a block with no spans has empty text', () {
      expect(
        const MarkdownBlock(type: MarkdownBlockType.rule).plainText,
        isEmpty,
      );
    });

    test('equality compares the spans one by one', () {
      expect(
        block,
        const MarkdownBlock(
          type: MarkdownBlockType.paragraph,
          spans: <MarkdownSpan>[
            MarkdownSpan('one '),
            MarkdownSpan('two', style: MarkdownSpanStyle.bold),
          ],
        ),
      );
    });

    test('a different span list is a different block', () {
      expect(
        block,
        isNot(
          const MarkdownBlock(
            type: MarkdownBlockType.paragraph,
            spans: <MarkdownSpan>[MarkdownSpan('one ')],
          ),
        ),
      );
    });

    test('a different type is a different block', () {
      expect(block, isNot(block.copyWith(type: MarkdownBlockType.quote)));
    });

    test('copyWith keeps what it is not given', () {
      final ticked = block.copyWith(isChecked: true);
      expect(ticked.isChecked, isTrue);
      expect(ticked.spans, block.spans);
    });
  });
}

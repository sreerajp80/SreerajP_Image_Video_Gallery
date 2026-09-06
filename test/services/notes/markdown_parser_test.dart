import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/notes/markdown_block.dart';
import 'package:in_sreerajp_imgvidgal/models/notes/markdown_span.dart';
import 'package:in_sreerajp_imgvidgal/services/notes/markdown_parser.dart';

const _parser = MarkdownParser();

void main() {
  group('blocks', () {
    test('empty text gives no blocks', () {
      expect(_parser.parse(''), isEmpty);
      expect(_parser.parse('   \n\n  '), isEmpty);
    });

    test('a plain line is a paragraph', () {
      final blocks = _parser.parse('Taken at Kovalam beach.');
      expect(blocks, hasLength(1));
      expect(blocks.first.type, MarkdownBlockType.paragraph);
      expect(blocks.first.plainText, 'Taken at Kovalam beach.');
    });

    test('wrapped lines join into one paragraph', () {
      final blocks = _parser.parse('first line\nsecond line');
      expect(blocks, hasLength(1));
      expect(blocks.first.plainText, 'first line second line');
    });

    test('a blank line starts a new paragraph', () {
      final blocks = _parser.parse('one\n\ntwo');
      expect(blocks, hasLength(2));
      expect(
        blocks.every((b) => b.type == MarkdownBlockType.paragraph),
        isTrue,
      );
    });

    test('headings carry their level', () {
      final blocks = _parser.parse('# One\n## Two\n### Three');
      expect(
        blocks.map((b) => b.type),
        everyElement(MarkdownBlockType.heading),
      );
      expect(blocks.map((b) => b.level), <int>[1, 2, 3]);
      expect(blocks.first.plainText, 'One');
    });

    test('a fourth level hash is not a heading', () {
      expect(
        _parser.parse('#### Four').first.type,
        MarkdownBlockType.paragraph,
      );
    });

    test('a hash with no space is not a heading', () {
      expect(_parser.parse('#tag').first.type, MarkdownBlockType.paragraph);
    });

    test('bullets are read with all three markers', () {
      final blocks = _parser.parse('- one\n* two\n+ three');
      expect(blocks, hasLength(3));
      expect(blocks.map((b) => b.type), everyElement(MarkdownBlockType.bullet));
      expect(blocks.last.plainText, 'three');
    });

    test('numbered items keep their number', () {
      final blocks = _parser.parse('1. first\n2) second');
      expect(
        blocks.map((b) => b.type),
        everyElement(MarkdownBlockType.numbered),
      );
      expect(blocks.map((b) => b.number), <int>[1, 2]);
    });

    test('task items are read before bullets, and keep the tick', () {
      final blocks = _parser.parse('- [ ] to do\n- [x] done\n- [X] also done');
      expect(blocks.map((b) => b.type), everyElement(MarkdownBlockType.task));
      expect(blocks.map((b) => b.isChecked), <bool>[false, true, true]);
      expect(blocks.first.plainText, 'to do');
    });

    test('a quote drops the marker', () {
      final block = _parser.parse('> remember this').first;
      expect(block.type, MarkdownBlockType.quote);
      expect(block.plainText, 'remember this');
    });

    test('all three rule forms are read', () {
      for (final source in <String>['---', '***', '___']) {
        final block = _parser.parse(source).first;
        expect(block.type, MarkdownBlockType.rule, reason: source);
        expect(block.spans, isEmpty);
      }
    });

    test('a fenced block keeps its text exactly', () {
      final blocks = _parser.parse('```\nline one\n  indented\n```');
      expect(blocks, hasLength(1));
      expect(blocks.first.type, MarkdownBlockType.code);
      expect(blocks.first.plainText, 'line one\n  indented');
    });

    test('markers inside a fenced block are not read', () {
      final block = _parser.parse('```\n**not bold**\n```').first;
      expect(block.plainText, '**not bold**');
      expect(block.spans.single.style, MarkdownSpanStyle.code);
    });

    test('an unclosed fence takes the rest of the note', () {
      final block = _parser.parse('```\nstill open\nmore').first;
      expect(block.type, MarkdownBlockType.code);
      expect(block.plainText, 'still open\nmore');
    });

    test('a paragraph does not swallow the list under it', () {
      final blocks = _parser.parse('Shopping\n- rice\n- oil');
      expect(blocks, hasLength(3));
      expect(blocks.first.type, MarkdownBlockType.paragraph);
      expect(blocks[1].type, MarkdownBlockType.bullet);
    });

    test('a mixed note keeps every block in order', () {
      final blocks = _parser.parse(
        '# Trip\n\nWe went early.\n\n- [x] pack\n- [ ] print\n\n> good light\n\n---',
      );
      expect(blocks.map((b) => b.type), <MarkdownBlockType>[
        MarkdownBlockType.heading,
        MarkdownBlockType.paragraph,
        MarkdownBlockType.task,
        MarkdownBlockType.task,
        MarkdownBlockType.quote,
        MarkdownBlockType.rule,
      ]);
    });

    test('windows line endings are handled', () {
      final blocks = _parser.parse('# One\r\n\r\ntext');
      expect(blocks, hasLength(2));
      expect(blocks.first.plainText, 'One');
    });
  });

  group('inline styling', () {
    List<MarkdownSpan> spansOf(String source) =>
        _parser.parse(source).first.spans;

    test('bold is read with both markers', () {
      expect(spansOf('**loud**').single.style, MarkdownSpanStyle.bold);
      expect(spansOf('__loud__').single.style, MarkdownSpanStyle.bold);
      expect(spansOf('**loud**').single.text, 'loud');
    });

    test('italic is read with both markers', () {
      expect(spansOf('*soft*').single.style, MarkdownSpanStyle.italic);
      expect(spansOf('_soft_').single.style, MarkdownSpanStyle.italic);
    });

    test('bold wins over italic, so double stars are not two italics', () {
      final spans = spansOf('**both**');
      expect(spans, hasLength(1));
      expect(spans.single.style, MarkdownSpanStyle.bold);
    });

    test('strikethrough and code are read', () {
      expect(spansOf('~~gone~~').single.style, MarkdownSpanStyle.strikethrough);
      expect(spansOf('`code`').single.style, MarkdownSpanStyle.code);
    });

    test('styled and plain runs sit side by side in order', () {
      final spans = spansOf('start **middle** end');
      expect(spans.map((s) => s.text), <String>['start ', 'middle', ' end']);
      expect(spans.map((s) => s.style), <MarkdownSpanStyle>[
        MarkdownSpanStyle.plain,
        MarkdownSpanStyle.bold,
        MarkdownSpanStyle.plain,
      ]);
    });

    test('a link keeps its label and target apart', () {
      final span = spansOf('[the map](https://example.com/map)').single;
      expect(span.style, MarkdownSpanStyle.link);
      expect(span.text, 'the map');
      expect(span.target, 'https://example.com/map');
    });

    test('a link target is kept exactly, however odd', () {
      // The parser does not judge the target: it records what was written and
      // leaves the question of what may be opened to the scheme rule in the
      // renderer. So a hostile target parses fine, and is refused later.
      final span = spansOf('[x](javascript:alert)').single;
      expect(span.style, MarkdownSpanStyle.link);
      expect(span.target, 'javascript:alert');
    });

    test('an unclosed link is plain text, not a link', () {
      final spans = spansOf('[x](https://example.com');
      expect(spans.every((s) => s.style != MarkdownSpanStyle.link), isTrue);
    });

    test('a backslash escapes a marker', () {
      final spans = spansOf(r'a \*not italic\* b');
      expect(spans.every((s) => s.style == MarkdownSpanStyle.plain), isTrue);
      expect(spans.map((s) => s.text).join(), 'a *not italic* b');
    });
  });

  group('half-typed markdown never throws', () {
    const halfTyped = <String>[
      '**',
      '**unclosed',
      '*',
      '~~',
      '`',
      '[',
      '[label]',
      '[label](',
      '[](target)',
      '[label]()',
      '```',
      '- ',
      '- [',
      '- [ ]',
      '1.',
      '#',
      '# ',
      '>',
      r'\\',
      r'\\*',
      '****',
      '__ __',
    ];

    for (final source in halfTyped) {
      test('"$source" parses without throwing', () {
        expect(() => _parser.parse(source), returnsNormally);
      });
    }

    test('every character survives a round of plain text', () {
      const source = 'ഒരു കുറിപ്പ് 123 !@£\$%^&()';
      expect(_parser.parse(source).first.plainText, source);
    });

    test('a very long line does not hang the parser', () {
      final long = 'word ' * 5000;
      expect(() => _parser.parse(long), returnsNormally);
    });

    test('deeply repeated markers do not hang the parser', () {
      expect(() => _parser.parse('*' * 2000), returnsNormally);
      expect(() => _parser.parse('[' * 2000), returnsNormally);
    });
  });
}

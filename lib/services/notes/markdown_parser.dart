import 'package:in_sreerajp_imgvidgal/models/notes/markdown_block.dart';
import 'package:in_sreerajp_imgvidgal/models/notes/markdown_span.dart';

/// Turns note text into blocks and styled runs.
///
/// Pure, and deliberately a subset: headings, bullets, numbered items, task
/// items, quotes, fenced code, rules, and the inline forms bold, italic,
/// strikethrough, code and link. That covers what people actually write in a
/// note about a photo.
///
/// It never throws. Half-typed markdown is the normal state of a note being
/// written, so an unclosed `**` or a `[label](` with no end is shown as the
/// plain text it currently is, and starts working the moment it is finished.
class MarkdownParser {
  const MarkdownParser();

  /// Reads [source] into blocks, in order.
  List<MarkdownBlock> parse(String source) {
    if (source.trim().isEmpty) return const <MarkdownBlock>[];

    final blocks = <MarkdownBlock>[];
    final lines = source.replaceAll('\r\n', '\n').split('\n');

    var index = 0;
    while (index < lines.length) {
      final line = lines[index];
      final trimmed = line.trim();

      if (trimmed.isEmpty) {
        index++;
        continue;
      }

      if (trimmed.startsWith('```')) {
        index = _readFencedCode(lines, index, blocks);
        continue;
      }

      if (_isRule(trimmed)) {
        blocks.add(const MarkdownBlock(type: MarkdownBlockType.rule));
        index++;
        continue;
      }

      final heading = _readHeading(trimmed);
      if (heading != null) {
        blocks.add(heading);
        index++;
        continue;
      }

      final task = _readTask(trimmed);
      if (task != null) {
        blocks.add(task);
        index++;
        continue;
      }

      final bullet = _readBullet(trimmed);
      if (bullet != null) {
        blocks.add(bullet);
        index++;
        continue;
      }

      final numbered = _readNumbered(trimmed);
      if (numbered != null) {
        blocks.add(numbered);
        index++;
        continue;
      }

      if (trimmed.startsWith('>')) {
        blocks.add(
          MarkdownBlock(
            type: MarkdownBlockType.quote,
            spans: parseInline(trimmed.substring(1).trim()),
          ),
        );
        index++;
        continue;
      }

      // Anything else is a paragraph, and neighbouring plain lines join into
      // one so a wrapped sentence does not become several stacked lines.
      final paragraph = StringBuffer(trimmed);
      index++;
      while (index < lines.length) {
        final next = lines[index].trim();
        if (next.isEmpty || _startsNewBlock(next)) break;
        paragraph.write(' ');
        paragraph.write(next);
        index++;
      }
      blocks.add(
        MarkdownBlock(
          type: MarkdownBlockType.paragraph,
          spans: parseInline(paragraph.toString()),
        ),
      );
    }

    return blocks;
  }

  /// Reads the inline styling inside one line of text.
  ///
  /// Public because the renderer needs it for a single line, and because it is
  /// worth testing on its own.
  List<MarkdownSpan> parseInline(String text) {
    if (text.isEmpty) return const <MarkdownSpan>[];

    final spans = <MarkdownSpan>[];
    final buffer = StringBuffer();
    var index = 0;

    void flush() {
      if (buffer.isEmpty) return;
      spans.add(MarkdownSpan(buffer.toString()));
      buffer.clear();
    }

    while (index < text.length) {
      final rest = text.substring(index);

      // A backslash escapes the next character, so a literal asterisk can be
      // written in a note about a file name.
      if (rest.startsWith(r'\') && rest.length > 1) {
        buffer.write(rest[1]);
        index += 2;
        continue;
      }

      final link = _readLink(rest);
      if (link != null) {
        flush();
        spans.add(link.span);
        index += link.length;
        continue;
      }

      final marked = _readMarked(rest);
      if (marked != null) {
        flush();
        spans.add(marked.span);
        index += marked.length;
        continue;
      }

      buffer.write(text[index]);
      index++;
    }

    flush();
    return spans;
  }

  /// Whether [line] would begin a block of its own.
  ///
  /// Used to stop a paragraph swallowing the bullet list under it.
  bool _startsNewBlock(String line) {
    return line.startsWith('#') ||
        line.startsWith('>') ||
        line.startsWith('```') ||
        _isRule(line) ||
        _readTask(line) != null ||
        _readBullet(line) != null ||
        _readNumbered(line) != null;
  }

  bool _isRule(String line) {
    return line == '---' || line == '***' || line == '___';
  }

  MarkdownBlock? _readHeading(String line) {
    final match = RegExp(r'^(#{1,3})\s+(.*)$').firstMatch(line);
    if (match == null) return null;

    return MarkdownBlock(
      type: MarkdownBlockType.heading,
      level: match.group(1)!.length,
      spans: parseInline(match.group(2)!.trim()),
    );
  }

  MarkdownBlock? _readTask(String line) {
    final match = RegExp(r'^[-*]\s+\[([ xX])\]\s*(.*)$').firstMatch(line);
    if (match == null) return null;

    return MarkdownBlock(
      type: MarkdownBlockType.task,
      isChecked: match.group(1)!.toLowerCase() == 'x',
      spans: parseInline(match.group(2)!.trim()),
    );
  }

  MarkdownBlock? _readBullet(String line) {
    final match = RegExp(r'^[-*+]\s+(.*)$').firstMatch(line);
    if (match == null) return null;

    return MarkdownBlock(
      type: MarkdownBlockType.bullet,
      spans: parseInline(match.group(1)!.trim()),
    );
  }

  MarkdownBlock? _readNumbered(String line) {
    final match = RegExp(r'^(\d{1,9})[.)]\s+(.*)$').firstMatch(line);
    if (match == null) return null;

    return MarkdownBlock(
      type: MarkdownBlockType.numbered,
      number: int.tryParse(match.group(1)!) ?? 1,
      spans: parseInline(match.group(2)!.trim()),
    );
  }

  /// Reads a ``` block, and returns the line to carry on from.
  ///
  /// An unclosed fence takes the rest of the note, which is what the writer
  /// sees in every other markdown editor.
  int _readFencedCode(List<String> lines, int start, List<MarkdownBlock> out) {
    final body = <String>[];
    var index = start + 1;

    while (index < lines.length && !lines[index].trim().startsWith('```')) {
      body.add(lines[index]);
      index++;
    }

    out.add(
      MarkdownBlock(
        type: MarkdownBlockType.code,
        spans: <MarkdownSpan>[
          MarkdownSpan(body.join('\n'), style: MarkdownSpanStyle.code),
        ],
      ),
    );

    // Step past the closing fence when there was one.
    return index < lines.length ? index + 1 : index;
  }

  /// Reads `[label](target)` from the front of [rest].
  _SpanMatch? _readLink(String rest) {
    if (!rest.startsWith('[')) return null;

    final labelEnd = rest.indexOf(']');
    if (labelEnd <= 0) return null;
    if (labelEnd + 1 >= rest.length || rest[labelEnd + 1] != '(') return null;

    final targetEnd = rest.indexOf(')', labelEnd + 2);
    if (targetEnd < 0) return null;

    final label = rest.substring(1, labelEnd);
    final target = rest.substring(labelEnd + 2, targetEnd).trim();
    if (label.isEmpty || target.isEmpty) return null;

    return _SpanMatch(MarkdownSpan.link(label, target), targetEnd + 1);
  }

  /// Reads a `**`, `~~`, `*`, `_` or `` ` `` run from the front of [rest].
  _SpanMatch? _readMarked(String rest) {
    // Longest markers first, so `**bold**` is not read as two italics.
    const markers = <String, MarkdownSpanStyle>{
      '**': MarkdownSpanStyle.bold,
      '__': MarkdownSpanStyle.bold,
      '~~': MarkdownSpanStyle.strikethrough,
      '`': MarkdownSpanStyle.code,
      '*': MarkdownSpanStyle.italic,
      '_': MarkdownSpanStyle.italic,
    };

    for (final entry in markers.entries) {
      final marker = entry.key;
      if (!rest.startsWith(marker)) continue;

      final closing = rest.indexOf(marker, marker.length);
      if (closing < 0) continue;

      final inner = rest.substring(marker.length, closing);
      if (inner.isEmpty || inner.trim().isEmpty) continue;

      return _SpanMatch(
        MarkdownSpan(inner, style: entry.value),
        closing + marker.length,
      );
    }

    return null;
  }
}

/// A span read off the front of a line, and how many characters it used.
class _SpanMatch {
  final MarkdownSpan span;
  final int length;

  const _SpanMatch(this.span, this.length);
}

import 'package:in_sreerajp_imgvidgal/models/notes/markdown_span.dart';

/// What kind of block a line or group of lines became.
enum MarkdownBlockType {
  /// A run of ordinary text.
  paragraph,

  /// `#`, `##` or `###`, with the level in `MarkdownBlock.level`.
  heading,

  /// A `-` or `*` bullet.
  bullet,

  /// A `1.` numbered item.
  numbered,

  /// A `- [ ]` or `- [x]` checklist item.
  task,

  /// A `>` quotation.
  quote,

  /// A ``` fenced block, kept exactly as typed.
  code,

  /// A `---` line.
  rule,
}

/// One block of a parsed note.
///
/// Immutable, and holds no widgets: the parser is pure Dart and unit tested on
/// its own, and `MarkdownView` is the only thing that knows how to draw these.
class MarkdownBlock {
  final MarkdownBlockType type;

  /// The styled runs making up the block's text.
  ///
  /// Empty for [MarkdownBlockType.rule], and a single plain span for
  /// [MarkdownBlockType.code], where markers are not read.
  final List<MarkdownSpan> spans;

  /// Heading level, 1 to 3. Zero for anything else.
  final int level;

  /// Whether a task item is ticked.
  final bool isChecked;

  /// The number shown by a numbered item.
  final int number;

  const MarkdownBlock({
    required this.type,
    this.spans = const <MarkdownSpan>[],
    this.level = 0,
    this.isChecked = false,
    this.number = 0,
  });

  /// The block's text with all styling dropped.
  ///
  /// Used for the one-line preview in the details sheet.
  String get plainText => spans.map((span) => span.text).join();

  MarkdownBlock copyWith({
    MarkdownBlockType? type,
    List<MarkdownSpan>? spans,
    int? level,
    bool? isChecked,
    int? number,
  }) {
    return MarkdownBlock(
      type: type ?? this.type,
      spans: spans ?? this.spans,
      level: level ?? this.level,
      isChecked: isChecked ?? this.isChecked,
      number: number ?? this.number,
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is! MarkdownBlock) return false;
    if (other.type != type ||
        other.level != level ||
        other.isChecked != isChecked ||
        other.number != number ||
        other.spans.length != spans.length) {
      return false;
    }
    for (var index = 0; index < spans.length; index++) {
      if (other.spans[index] != spans[index]) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hash(type, level, isChecked, number, Object.hashAll(spans));

  @override
  String toString() => 'MarkdownBlock(${type.name}: $plainText)';
}

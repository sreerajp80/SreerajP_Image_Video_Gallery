/// How a run of text inside a block is styled.
enum MarkdownSpanStyle {
  /// No styling at all.
  plain,

  /// `**bold**`.
  bold,

  /// `*italic*` or `_italic_`.
  italic,

  /// `~~struck through~~`.
  strikethrough,

  /// `` `code` ``.
  code,

  /// `[label](target)`.
  link,
}

/// One styled run of text.
///
/// Spans do not nest. Bold inside italic is a nicety the notes editor does not
/// need, and flattening keeps both the parser and the renderer small enough to
/// reason about.
class MarkdownSpan {
  /// The text as the reader should see it, with the markers already removed.
  final String text;

  /// How it is styled.
  final MarkdownSpanStyle style;

  /// Where a link points, for [MarkdownSpanStyle.link] only.
  ///
  /// Kept exactly as written. Whether it may be opened is decided later, by
  /// the same scheme rule the scanner uses.
  final String target;

  const MarkdownSpan(this.text, {this.style = MarkdownSpanStyle.plain})
    : target = '';

  const MarkdownSpan.link(this.text, this.target)
    : style = MarkdownSpanStyle.link;

  const MarkdownSpan.raw({
    required this.text,
    required this.style,
    required this.target,
  });

  @override
  bool operator ==(Object other) {
    return other is MarkdownSpan &&
        other.text == text &&
        other.style == style &&
        other.target == target;
  }

  @override
  int get hashCode => Object.hash(text, style, target);

  @override
  String toString() => 'MarkdownSpan(${style.name}: $text)';
}

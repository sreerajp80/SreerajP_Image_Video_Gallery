import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/notes/markdown_block.dart';
import 'package:in_sreerajp_imgvidgal/models/notes/markdown_span.dart';
import 'package:in_sreerajp_imgvidgal/services/notes/markdown_parser.dart';
import 'package:in_sreerajp_imgvidgal/widgets/common/adaptive_directionality.dart';

/// Draws a parsed note.
///
/// The parsing is done by [MarkdownParser], which is pure and tested on its
/// own; this widget only turns blocks into text spans.
///
/// A link is tappable only when its target uses a scheme the app will launch,
/// which is the same permitted list the code scanner uses. A note can hold any
/// text at all, including text pasted in from a scanned code, so a link in one
/// is no more trusted than a link on a poster.
class MarkdownView extends StatefulWidget {
  /// The note's markdown source.
  final String source;

  /// Called when the reader taps a link the app is willing to open.
  final void Function(String target)? onOpenLink;

  /// Called when the reader taps a link the app will not open.
  final VoidCallback? onBlockedLink;

  /// Shown when [source] holds nothing.
  final Widget? emptyState;

  const MarkdownView({
    super.key,
    required this.source,
    this.onOpenLink,
    this.onBlockedLink,
    this.emptyState,
  });

  /// Whether a link target uses a scheme the app is willing to launch.
  ///
  /// The same permitted list the code scanner uses. A bare address with no
  /// scheme is treated as `https`, matching what the scanner does.
  static bool isOpenableLink(String target) {
    final trimmed = target.trim();
    if (trimmed.isEmpty) return false;

    final candidate = trimmed.contains('://') || trimmed.contains(':')
        ? trimmed
        : 'https://$trimmed';

    final uri = Uri.tryParse(candidate);
    if (uri == null) return false;

    return AppConstants.scanLaunchableSchemes.contains(
      uri.scheme.toLowerCase(),
    );
  }

  @override
  State<MarkdownView> createState() => _MarkdownViewState();
}

class _MarkdownViewState extends State<MarkdownView> {
  static const _parser = MarkdownParser();

  /// Recognisers have to be disposed, so they are kept rather than rebuilt
  /// inline and dropped on the floor.
  final List<TapGestureRecognizer> _recognisers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    _clearRecognisers();
    super.dispose();
  }

  void _clearRecognisers() {
    for (final recogniser in _recognisers) {
      recogniser.dispose();
    }
    _recognisers.clear();
  }

  @override
  Widget build(BuildContext context) {
    _clearRecognisers();

    final blocks = _parser.parse(widget.source);
    if (blocks.isEmpty) {
      return widget.emptyState ?? const SizedBox.shrink();
    }

    // The whole note flows the way its own text reads, so a note written in
    // a right-to-left script is not laid out backwards.
    return AdaptiveDirectionality(
      text: widget.source,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final block in blocks) _buildBlock(context, block),
        ],
      ),
    );
  }

  Widget _buildBlock(BuildContext context, MarkdownBlock block) {
    final theme = Theme.of(context);

    switch (block.type) {
      case MarkdownBlockType.rule:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Divider(height: 1),
        );

      case MarkdownBlockType.heading:
        final style = switch (block.level) {
          1 => theme.textTheme.headlineSmall,
          2 => theme.textTheme.titleLarge,
          _ => theme.textTheme.titleMedium,
        };
        return Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: _text(
            context,
            block,
            style?.copyWith(fontWeight: FontWeight.w600),
          ),
        );

      case MarkdownBlockType.code:
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SelectableText(
              block.plainText,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
          ),
        );

      case MarkdownBlockType.quote:
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.only(left: 12),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: theme.colorScheme.outline, width: 3),
            ),
          ),
          child: _text(
            context,
            block,
            theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        );

      case MarkdownBlockType.bullet:
        return _listRow(context, block, const Text('•  '));

      case MarkdownBlockType.numbered:
        return _listRow(context, block, Text('${block.number}.  '));

      case MarkdownBlockType.task:
        return _listRow(
          context,
          block,
          Padding(
            padding: const EdgeInsets.only(right: 6, top: 2),
            child: Icon(
              block.isChecked
                  ? Icons.check_box_outlined
                  : Icons.check_box_outline_blank,
              size: 18,
              color: theme.colorScheme.primary,
            ),
          ),
        );

      case MarkdownBlockType.paragraph:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: _text(context, block, theme.textTheme.bodyMedium),
        );
    }
  }

  Widget _listRow(BuildContext context, MarkdownBlock block, Widget leading) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 2, left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          leading,
          Expanded(
            child: _text(
              context,
              block,
              Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _text(BuildContext context, MarkdownBlock block, TextStyle? base) {
    return SelectableText.rich(
      TextSpan(
        style: base,
        children: <InlineSpan>[
          for (final span in block.spans) _buildSpan(context, span, base),
        ],
      ),
    );
  }

  InlineSpan _buildSpan(
    BuildContext context,
    MarkdownSpan span,
    TextStyle? base,
  ) {
    final theme = Theme.of(context);

    switch (span.style) {
      case MarkdownSpanStyle.plain:
        return TextSpan(text: span.text);

      case MarkdownSpanStyle.bold:
        return TextSpan(
          text: span.text,
          style: const TextStyle(fontWeight: FontWeight.bold),
        );

      case MarkdownSpanStyle.italic:
        return TextSpan(
          text: span.text,
          style: const TextStyle(fontStyle: FontStyle.italic),
        );

      case MarkdownSpanStyle.strikethrough:
        return TextSpan(
          text: span.text,
          style: const TextStyle(decoration: TextDecoration.lineThrough),
        );

      case MarkdownSpanStyle.code:
        return TextSpan(
          text: span.text,
          style: TextStyle(
            fontFamily: 'monospace',
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        );

      case MarkdownSpanStyle.link:
        final openable = MarkdownView.isOpenableLink(span.target);
        final recogniser = TapGestureRecognizer()
          ..onTap = () {
            if (openable) {
              widget.onOpenLink?.call(span.target);
            } else {
              widget.onBlockedLink?.call();
            }
          };
        _recognisers.add(recogniser);

        return TextSpan(
          text: span.text,
          recognizer: recogniser,
          style: TextStyle(
            // A link the app will not open does not get to look like one.
            color: openable
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
            decoration: openable ? TextDecoration.underline : null,
          ),
        );
    }
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';

/// Height of the draggable thumb.
const double kScrubberThumbHeight = 44;

/// Width of the draggable thumb.
const double kScrubberThumbWidth = 28;

/// A draggable fast-scroll handle with a floating date bubble.
///
/// It overlays the trailing edge of the timeline, appears while the list is
/// moving, and fades out after a short idle pause. Dragging maps the vertical
/// position onto the scroll range so a large library can be crossed in one
/// gesture. It hides itself when the list is too short to need it.
class FastScrollScrubber extends StatefulWidget {
  /// Controller of the list being scrubbed.
  final ScrollController controller;

  /// Returns the label to show for a given scroll offset, or null for none.
  final String? Function(double offset) labelForOffset;

  /// Scroll extent below which the scrubber stays hidden.
  final double minScrollExtent;

  /// How long the thumb stays visible after the last movement.
  final Duration fadeOutDelay;

  const FastScrollScrubber({
    super.key,
    required this.controller,
    required this.labelForOffset,
    this.minScrollExtent = 1200,
    this.fadeOutDelay = const Duration(milliseconds: 1600),
  });

  @override
  State<FastScrollScrubber> createState() => _FastScrollScrubberState();
}

class _FastScrollScrubberState extends State<FastScrollScrubber> {
  bool _visible = false;
  bool _dragging = false;
  double _fraction = 0;
  Timer? _fadeTimer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant FastScrollScrubber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onScroll);
      widget.controller.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    _fadeTimer?.cancel();
    widget.controller.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (_dragging || !mounted) return;
    if (!widget.controller.hasClients) return;

    final position = widget.controller.position;
    final range = position.maxScrollExtent - position.minScrollExtent;
    if (range <= 0) return;

    final next = ((position.pixels - position.minScrollExtent) / range).clamp(
      0.0,
      1.0,
    );

    setState(() {
      _fraction = next;
      _visible = true;
    });
    _scheduleFadeOut();
  }

  void _scheduleFadeOut() {
    _fadeTimer?.cancel();
    _fadeTimer = Timer(widget.fadeOutDelay, () {
      if (!mounted || _dragging) return;
      setState(() => _visible = false);
    });
  }

  void _jumpToFraction(double fraction) {
    if (!widget.controller.hasClients) return;

    final position = widget.controller.position;
    final range = position.maxScrollExtent - position.minScrollExtent;
    if (range <= 0) return;

    final clamped = fraction.clamp(0.0, 1.0);
    setState(() => _fraction = clamped);
    widget.controller.jumpTo(position.minScrollExtent + range * clamped);
  }

  /// Current scroll offset implied by the thumb position.
  double get _offsetForFraction {
    if (!widget.controller.hasClients ||
        !widget.controller.position.hasContentDimensions) {
      return 0;
    }
    final position = widget.controller.position;
    final range = position.maxScrollExtent - position.minScrollExtent;
    return position.minScrollExtent + range * _fraction;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // Short lists scroll fine on their own; a scrubber would only be clutter.
    final scrollable =
        widget.controller.hasClients &&
        widget.controller.position.hasContentDimensions &&
        widget.controller.position.maxScrollExtent >= widget.minScrollExtent;
    if (!scrollable) return const SizedBox.shrink();

    final label = widget.labelForOffset(_offsetForFraction);

    return Positioned.directional(
      textDirection: Directionality.of(context),
      top: 0,
      bottom: 0,
      end: 2,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final trackHeight = constraints.maxHeight - kScrubberThumbHeight;
          if (trackHeight <= 0) return const SizedBox.shrink();

          return AnimatedOpacity(
            opacity: _visible || _dragging ? 1 : 0,
            duration: const Duration(milliseconds: 220),
            child: IgnorePointer(
              ignoring: !(_visible || _dragging),
              child: SizedBox(
                width: 220,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.directional(
                      textDirection: Directionality.of(context),
                      top: trackHeight * _fraction,
                      end: 0,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onVerticalDragStart: (_) {
                          _fadeTimer?.cancel();
                          setState(() => _dragging = true);
                        },
                        onVerticalDragUpdate: (details) {
                          _jumpToFraction(
                            _fraction + details.delta.dy / trackHeight,
                          );
                        },
                        onVerticalDragEnd: (_) {
                          setState(() => _dragging = false);
                          _scheduleFadeOut();
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (_dragging && label != null)
                              _DateBubble(label: label),
                            Semantics(
                              label: l10n.scrollToDate,
                              value: label,
                              child: Container(
                                width: kScrubberThumbWidth,
                                height: kScrubberThumbHeight,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius:
                                      const BorderRadiusDirectional.horizontal(
                                        start: Radius.circular(
                                          kScrubberThumbHeight,
                                        ),
                                      ),
                                ),
                                child: Icon(
                                  Icons.drag_handle_rounded,
                                  size: 18,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DateBubble extends StatelessWidget {
  final String label;

  const _DateBubble({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: Material(
        elevation: 3,
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.inverseSurface,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onInverseSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

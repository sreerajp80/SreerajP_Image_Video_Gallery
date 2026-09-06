import 'package:flutter/widgets.dart';
import 'package:in_sreerajp_imgvidgal/core/text/text_direction.dart';

/// Lays out [child] in the direction [text] actually reads in.
///
/// Use this around text the app did not write: notes, recognised text from a
/// photo, scanned code payloads, tag and album names, file names. Do not use
/// it around translated labels — those already follow the chosen language,
/// and second-guessing them would be wrong.
///
/// When [text] holds nothing directional (empty, only digits, only
/// punctuation) the ambient direction is kept, so a neutral string never
/// flips the layout around it.
///
/// The widget adds no padding, no constraints, and no extra render object
/// beyond the [Directionality] itself.
class AdaptiveDirectionality extends StatelessWidget {
  /// The text whose direction decides the layout.
  final String text;

  /// The widget laid out in that direction. Usually shows [text].
  final Widget child;

  /// Direction used when [text] has nothing directional in it.
  ///
  /// Defaults to the direction already in force at this point in the tree.
  final TextDirection? fallback;

  const AdaptiveDirectionality({
    super.key,
    required this.text,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final TextDirection direction =
        detectTextDirection(text) ?? fallback ?? Directionality.of(context);

    return Directionality(textDirection: direction, child: child);
  }
}

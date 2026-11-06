import 'package:material_ui/material_ui.dart';

/// What a widget shows in a release build when it fails to build.
///
/// Installed through `ErrorWidget.builder` in `main.dart` (engineering
/// standard §11.1). It replaces Flutter's grey error box with a quiet icon.
///
/// It must not be able to fail the same way, so it reads nothing from the
/// tree: no theme, no localizations, no providers, and no exception text.
/// That is also why it has no words — it cannot know the user's language.
class SafeErrorFallback extends StatelessWidget {
  const SafeErrorFallback({super.key});

  @override
  Widget build(BuildContext context) {
    return const Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: Color(0x00000000),
        child: Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 32,
            color: Color(0xFF9E9E9E),
          ),
        ),
      ),
    );
  }
}

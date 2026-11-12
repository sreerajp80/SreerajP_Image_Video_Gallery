import 'package:material_ui/material_ui.dart';

/// A short line of text over a camera picture, near the bottom.
///
/// Fixed light-on-dark, whatever the theme, because it sits on top of a live
/// camera image that can be any colour.
class CameraCaption extends StatelessWidget {
  final String text;

  const CameraCaption({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 32,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

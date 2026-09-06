import 'package:flutter/material.dart';
import 'package:in_sreerajp_imgvidgal/services/video/video_gesture_service.dart';

/// Floating indicator shown while a brightness, volume, or seek drag is active.
///
/// It is a plain presentation widget: the numbers and the label are worked out
/// by `VideoGestureService` and handed in already finished.
class GestureHud extends StatelessWidget {
  /// What the drag is doing right now.
  final VideoGestureKind kind;

  /// Brightness or volume level from 0 to 1, ignored for a seek.
  final double level;

  /// Text shown for a seek, such as `1:20 / 4:05`.
  final String? seekLabel;

  const GestureHud({
    super.key,
    required this.kind,
    required this.level,
    this.seekLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (kind == VideoGestureKind.none) return const SizedBox.shrink();

    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_icon, color: Colors.white, size: 32),
              const SizedBox(height: 10),
              if (kind == VideoGestureKind.seek)
                Text(
                  seekLabel ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else ...[
                SizedBox(
                  width: 120,
                  child: LinearProgressIndicator(
                    value: level.clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${(level.clamp(0.0, 1.0) * 100).round()}%',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData get _icon {
    switch (kind) {
      case VideoGestureKind.brightness:
        return Icons.brightness_6_outlined;
      case VideoGestureKind.volume:
        return level <= 0
            ? Icons.volume_off_outlined
            : Icons.volume_up_outlined;
      case VideoGestureKind.seek:
        return Icons.fast_forward_outlined;
      case VideoGestureKind.none:
        return Icons.circle_outlined;
    }
  }
}

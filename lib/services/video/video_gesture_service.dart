import 'dart:ui';

import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';

/// What a drag over the video surface is currently doing.
enum VideoGestureKind {
  /// No gesture is active.
  none,

  /// A vertical drag on the left half changes screen brightness.
  brightness,

  /// A vertical drag on the right half changes player volume.
  volume,

  /// A horizontal drag scrubs the playhead.
  seek,
}

/// Turns finger movement over the video into brightness, volume, or seek.
///
/// Every method is a pure calculation over numbers, so the gesture rules are
/// unit tested with no player, no screen, and no device.
class VideoGestureService {
  const VideoGestureService();

  /// Decides what a drag means from where it started and which way it goes.
  ///
  /// The first movement wins: a clearly sideways drag seeks, and an up or down
  /// drag changes a level. Which level depends on the half of the screen the
  /// finger started in — left for brightness, right for volume, the same
  /// convention most video apps use.
  VideoGestureKind classify({
    required Offset startPosition,
    required Offset delta,
    required Size surfaceSize,
  }) {
    if (surfaceSize.width <= 0 || surfaceSize.height <= 0) {
      return VideoGestureKind.none;
    }
    if (delta.dx == 0 && delta.dy == 0) return VideoGestureKind.none;

    if (delta.dx.abs() > delta.dy.abs()) return VideoGestureKind.seek;

    return startPosition.dx < surfaceSize.width / 2
        ? VideoGestureKind.brightness
        : VideoGestureKind.volume;
  }

  /// The new brightness or volume after a vertical drag of [deltaY] pixels.
  ///
  /// Dragging up raises the level, which is why the delta is subtracted: on a
  /// screen, y grows downward.
  double applyLevelDrag({
    required double currentLevel,
    required double deltaY,
  }) {
    if (deltaY.isNaN || currentLevel.isNaN) return clampLevel(currentLevel);
    final change = -deltaY / AppConstants.videoLevelDragReferencePx;
    return clampLevel(currentLevel + change);
  }

  /// Keeps a brightness or volume level between 0 and 1.
  double clampLevel(double level) {
    if (level.isNaN) return 0;
    return level.clamp(0.0, 1.0);
  }

  /// The seek target after a horizontal drag of [deltaX] pixels.
  ///
  /// The drag is scaled against the clip length, so the same finger movement
  /// moves a short clip by a little and a long clip by a lot. A single drag can
  /// never jump more than `AppConstants.videoSeekDragMaxMs`, which stops an
  /// accidental swipe from throwing the user to the far end of a long video.
  Duration applySeekDrag({
    required Duration position,
    required Duration duration,
    required double deltaX,
  }) {
    if (duration <= Duration.zero || deltaX.isNaN || deltaX == 0) {
      return _clampPosition(position, duration);
    }

    final fraction = deltaX / AppConstants.videoSeekDragReferencePx;
    var deltaMs = (duration.inMilliseconds * fraction).round();
    deltaMs = deltaMs.clamp(
      -AppConstants.videoSeekDragMaxMs,
      AppConstants.videoSeekDragMaxMs,
    );

    return _clampPosition(position + Duration(milliseconds: deltaMs), duration);
  }

  /// The position under a tap on the seek bar, given a 0..1 [fraction].
  Duration positionForFraction({
    required double fraction,
    required Duration duration,
  }) {
    if (duration <= Duration.zero || fraction.isNaN) return Duration.zero;
    final clamped = fraction.clamp(0.0, 1.0);
    return Duration(milliseconds: (duration.inMilliseconds * clamped).round());
  }

  /// Formats a position as `m:ss`, or `h:mm:ss` for a clip an hour or longer.
  ///
  /// This is digits and colons only, the same in every language, so it is built
  /// here instead of in the ARB files.
  String formatDuration(Duration value) {
    final safe = value.isNegative ? Duration.zero : value;
    final hours = safe.inHours;
    final minutes = safe.inMinutes.remainder(60);
    final seconds = safe.inSeconds.remainder(60);

    final secondsText = seconds.toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:$secondsText';
    }
    return '$minutes:$secondsText';
  }

  Duration _clampPosition(Duration target, Duration duration) {
    if (target.isNegative) return Duration.zero;
    if (duration <= Duration.zero) return Duration.zero;
    return target > duration ? duration : target;
  }
}

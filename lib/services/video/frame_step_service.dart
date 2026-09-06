import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';

/// Works out where the playhead lands when the user steps one frame.
///
/// MediaStore does not report a frame rate, so a step is a fixed slice of time
/// (`AppConstants.frameStepMs`, one frame at 30 fps). That is close enough to
/// nudge through a clip, and it never depends on data we do not have.
class FrameStepService {
  /// Length of one step.
  final Duration frameDuration;

  const FrameStepService({
    this.frameDuration = const Duration(milliseconds: AppConstants.frameStepMs),
  });

  /// Position one frame after [position], never past the end of the clip.
  Duration nextFrame({required Duration position, required Duration duration}) {
    return _clamp(position + frameDuration, duration);
  }

  /// Position one frame before [position], never before the start.
  Duration previousFrame({
    required Duration position,
    required Duration duration,
  }) {
    return _clamp(position - frameDuration, duration);
  }

  /// Position [seconds] later, used by the skip-forward button.
  Duration skipForward({
    required Duration position,
    required Duration duration,
    int seconds = 10,
  }) {
    return _clamp(position + Duration(seconds: seconds), duration);
  }

  /// Position [seconds] earlier, used by the skip-back button.
  Duration skipBackward({
    required Duration position,
    required Duration duration,
    int seconds = 10,
  }) {
    return _clamp(position - Duration(seconds: seconds), duration);
  }

  /// Whether the clip is long enough to step through at all.
  bool canStep(Duration duration) => duration > Duration.zero;

  /// Keeps a target inside the clip.
  ///
  /// A clip of unknown length (duration zero) clamps to the start, so a step
  /// on an uninitialised player is harmless rather than a seek into nothing.
  Duration _clamp(Duration target, Duration duration) {
    if (target.isNegative) return Duration.zero;
    if (duration <= Duration.zero) return Duration.zero;
    return target > duration ? duration : target;
  }
}

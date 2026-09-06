import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';

/// The 0.25x to 2.0x playback speed ladder.
///
/// Pure value logic, so the control bar never has to reason about which speed
/// comes next or how to spell one.
class PlaybackSpeedService {
  const PlaybackSpeedService();

  /// Every speed the player offers, slowest first.
  static const List<double> speeds = AppConstants.playbackSpeeds;

  /// Speed a clip starts at.
  static const double defaultSpeed = AppConstants.defaultPlaybackSpeed;

  /// Slowest offered speed.
  double get minSpeed => speeds.first;

  /// Fastest offered speed.
  double get maxSpeed => speeds.last;

  /// Snaps any value to the nearest speed on the ladder.
  ///
  /// A stored or restored speed that is no longer on the ladder still resolves
  /// to something playable instead of throwing.
  double nearest(double speed) {
    if (speed.isNaN) return defaultSpeed;
    var best = speeds.first;
    var bestGap = (speed - best).abs();
    for (final candidate in speeds) {
      final gap = (speed - candidate).abs();
      if (gap < bestGap) {
        best = candidate;
        bestGap = gap;
      }
    }
    return best;
  }

  /// Position of [speed] on the ladder, after snapping it.
  int indexOf(double speed) => speeds.indexOf(nearest(speed));

  /// The next speed up, or the current one when already at the fastest.
  double faster(double speed) {
    final index = indexOf(speed);
    if (index >= speeds.length - 1) return speeds.last;
    return speeds[index + 1];
  }

  /// The next speed down, or the current one when already at the slowest.
  double slower(double speed) {
    final index = indexOf(speed);
    if (index <= 0) return speeds.first;
    return speeds[index - 1];
  }

  /// Whether a faster step is still available.
  bool canGoFaster(double speed) => indexOf(speed) < speeds.length - 1;

  /// Whether a slower step is still available.
  bool canGoSlower(double speed) => indexOf(speed) > 0;

  /// Short label for a speed, for example `0.25x` or `1x`.
  ///
  /// This is a number plus the letter x, not a translated sentence, so it is
  /// built here rather than in the ARB files.
  String label(double speed) {
    final snapped = nearest(speed);
    final text = snapped == snapped.roundToDouble()
        ? snapped.toStringAsFixed(0)
        : snapped.toString();
    return '${text}x';
  }
}

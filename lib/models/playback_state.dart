import 'package:flutter/foundation.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';

/// Why a clip could not be played, or [none] when it plays fine.
enum PlaybackError {
  /// Nothing went wrong.
  none,

  /// The file is missing, unreadable, or not a video at all.
  unreadable,

  /// The device has no decoder for this codec or container.
  unsupportedFormat,
}

/// Immutable snapshot of the video player, rebuilt on every tick.
///
/// It carries only plain values so the control bar can be drawn, and tested,
/// without a real platform player behind it.
@immutable
class PlaybackState {
  /// Whether the underlying player finished loading the clip.
  final bool isInitialized;

  /// Whether the clip is playing right now.
  final bool isPlaying;

  /// Whether the player is waiting for more data before it can continue.
  final bool isBuffering;

  /// Whether the clip restarts when it reaches the end.
  final bool isLooping;

  /// Playhead position.
  final Duration position;

  /// Total clip length, or [Duration.zero] until the clip is initialized.
  final Duration duration;

  /// Playback speed, one of `AppConstants.playbackSpeeds`.
  final double speed;

  /// Player output volume from 0.0 to 1.0.
  final double volume;

  /// Why playback failed, or [PlaybackError.none].
  final PlaybackError error;

  const PlaybackState({
    this.isInitialized = false,
    this.isPlaying = false,
    this.isBuffering = false,
    this.isLooping = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.speed = AppConstants.defaultPlaybackSpeed,
    this.volume = 1.0,
    this.error = PlaybackError.none,
  });

  /// State of a player that has not loaded anything yet.
  static const PlaybackState initial = PlaybackState();

  /// Whether the clip failed to load or play.
  bool get hasError => error != PlaybackError.none;

  /// Whether the controls may be used.
  bool get isReady => isInitialized && !hasError;

  /// Playhead position as a fraction of the clip, always between 0 and 1.
  ///
  /// It returns 0 for a clip of unknown length, which keeps the seek bar at the
  /// start instead of dividing by zero.
  double get progress {
    final total = duration.inMilliseconds;
    if (total <= 0) return 0;
    final ratio = position.inMilliseconds / total;
    if (ratio.isNaN) return 0;
    return ratio.clamp(0.0, 1.0);
  }

  /// Time left before the clip ends, never negative.
  Duration get remaining {
    final left = duration - position;
    return left.isNegative ? Duration.zero : left;
  }

  PlaybackState copyWith({
    bool? isInitialized,
    bool? isPlaying,
    bool? isBuffering,
    bool? isLooping,
    Duration? position,
    Duration? duration,
    double? speed,
    double? volume,
    PlaybackError? error,
  }) {
    return PlaybackState(
      isInitialized: isInitialized ?? this.isInitialized,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      isLooping: isLooping ?? this.isLooping,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      speed: speed ?? this.speed,
      volume: volume ?? this.volume,
      error: error ?? this.error,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaybackState &&
          runtimeType == other.runtimeType &&
          isInitialized == other.isInitialized &&
          isPlaying == other.isPlaying &&
          isBuffering == other.isBuffering &&
          isLooping == other.isLooping &&
          position == other.position &&
          duration == other.duration &&
          speed == other.speed &&
          volume == other.volume &&
          error == other.error;

  @override
  int get hashCode => Object.hash(
    isInitialized,
    isPlaying,
    isBuffering,
    isLooping,
    position,
    duration,
    speed,
    volume,
    error,
  );
}

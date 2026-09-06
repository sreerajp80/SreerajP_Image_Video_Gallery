import 'package:flutter/foundation.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/video/trim_range.dart';

/// How a slice of video should be turned into an animated GIF.
///
/// A GIF holds every frame as a full picture, so the frame rate, the size,
/// and the length together decide how big the file gets. The caps in
/// `AppConstants` stop a long selection from filling memory.
@immutable
class GifExportOptions {
  /// Frames captured per second of clip time.
  final int frameRate;

  /// Longest side of the finished GIF, in pixels.
  final int maxSide;

  /// The slice of the clip to cover.
  final TrimRange range;

  /// Whether the GIF plays over and over.
  final bool loop;

  const GifExportOptions({
    this.frameRate = AppConstants.gifDefaultFrameRate,
    this.maxSide = AppConstants.gifDefaultMaxSide,
    this.range = const TrimRange(startMs: 0, endMs: 0),
    this.loop = true,
  });

  /// The frame rate actually used, pulled into the offered range.
  int get effectiveFrameRate => frameRate.clamp(
    AppConstants.gifFrameRates.first,
    AppConstants.gifFrameRates.last,
  );

  /// The longest side actually used, pulled into the offered range.
  int get effectiveMaxSide => maxSide.clamp(
    AppConstants.gifSizeChoices.first,
    AppConstants.gifSizeChoices.last,
  );

  /// The gap between frames in the finished GIF, in milliseconds.
  int get frameDelayMs => (1000 / effectiveFrameRate).round();

  GifExportOptions copyWith({
    int? frameRate,
    int? maxSide,
    TrimRange? range,
    bool? loop,
  }) {
    return GifExportOptions(
      frameRate: frameRate ?? this.frameRate,
      maxSide: maxSide ?? this.maxSide,
      range: range ?? this.range,
      loop: loop ?? this.loop,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GifExportOptions &&
          runtimeType == other.runtimeType &&
          frameRate == other.frameRate &&
          maxSide == other.maxSide &&
          range == other.range &&
          loop == other.loop;

  @override
  int get hashCode => Object.hash(frameRate, maxSide, range, loop);

  @override
  String toString() =>
      'GifExportOptions($frameRate fps, $maxSide px, $range, loop: $loop)';
}

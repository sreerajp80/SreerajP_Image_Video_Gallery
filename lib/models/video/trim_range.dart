import 'package:flutter/foundation.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';

/// The slice of a clip the user wants to keep.
///
/// Both ends are in milliseconds from the start of the clip. The range is
/// only a request; the trim service is what clamps it against the real clip
/// length before anything is written.
@immutable
class TrimRange {
  final int startMs;
  final int endMs;

  const TrimRange({required this.startMs, required this.endMs});

  /// A range covering a whole clip of [durationMs].
  factory TrimRange.whole(int durationMs) =>
      TrimRange(startMs: 0, endMs: durationMs < 0 ? 0 : durationMs);

  /// How long the kept slice is, in milliseconds. Never negative.
  int get durationMs => endMs > startMs ? endMs - startMs : 0;

  /// Whether the range is long enough to be worth writing out.
  bool get isValid =>
      startMs >= 0 &&
      endMs > startMs &&
      durationMs >= AppConstants.trimMinDurationMs;

  /// Whether the range still covers the whole of a clip of [durationMs].
  bool coversAll(int durationMs) => startMs <= 0 && endMs >= durationMs;

  TrimRange copyWith({int? startMs, int? endMs}) =>
      TrimRange(startMs: startMs ?? this.startMs, endMs: endMs ?? this.endMs);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrimRange &&
          runtimeType == other.runtimeType &&
          startMs == other.startMs &&
          endMs == other.endMs;

  @override
  int get hashCode => Object.hash(startMs, endMs);

  @override
  String toString() => 'TrimRange($startMs ms to $endMs ms)';
}

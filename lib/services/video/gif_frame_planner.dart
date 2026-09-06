import 'dart:math' as math;

import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/video/gif_export_options.dart';

/// Decides exactly which moments of a clip become GIF frames.
///
/// Pure maths, and deliberately so: it is the piece that decides how much
/// memory a GIF export will use, so it must be easy to check. Nothing here
/// opens a clip or holds a picture.
class GifFramePlanner {
  const GifFramePlanner();

  /// The list of times, in milliseconds, to pull a frame from.
  ///
  /// The list is capped three ways, all of them protective:
  /// the chosen range is trimmed to the real clip length, the range is cut
  /// to the longest slice a GIF may cover, and the frame count is capped so
  /// a long selection cannot fill memory.
  List<int> plan({
    required GifExportOptions options,
    required int clipDurationMs,
  }) {
    if (clipDurationMs <= 0) return const <int>[];

    final start = options.range.startMs.clamp(0, clipDurationMs);
    final requestedEnd = options.range.endMs <= 0
        ? clipDurationMs
        : options.range.endMs;
    final end = requestedEnd.clamp(start, clipDurationMs);

    final available = end - start;
    if (available <= 0) return <int>[start];

    final span = math.min(available, AppConstants.gifMaxDurationMs);
    final step = math.max(1, (1000 / options.effectiveFrameRate).round());

    final times = <int>[];
    for (
      var time = start;
      time < start + span && times.length < AppConstants.gifMaxFrames;
      time += step
    ) {
      times.add(time);
    }

    // A very short slice still deserves one frame rather than none.
    if (times.isEmpty) times.add(start);

    return times;
  }

  /// How many frames [options] would produce for a clip of [clipDurationMs].
  ///
  /// The screen shows this next to the sliders, so the user can see a long
  /// selection being capped before they start the export.
  int frameCount({
    required GifExportOptions options,
    required int clipDurationMs,
  }) => plan(options: options, clipDurationMs: clipDurationMs).length;

  /// Whether the frame count was cut short by one of the caps.
  bool isCapped({
    required GifExportOptions options,
    required int clipDurationMs,
  }) {
    if (clipDurationMs <= 0) return false;

    final start = options.range.startMs.clamp(0, clipDurationMs);
    final requestedEnd = options.range.endMs <= 0
        ? clipDurationMs
        : options.range.endMs;
    final end = requestedEnd.clamp(start, clipDurationMs);

    if (end - start > AppConstants.gifMaxDurationMs) return true;
    return frameCount(options: options, clipDurationMs: clipDurationMs) >=
        AppConstants.gifMaxFrames;
  }
}

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/video/trim_range.dart';
import 'package:in_sreerajp_imgvidgal/services/convert/output_naming_service.dart';
import 'package:in_sreerajp_imgvidgal/services/video/video_tools_channel.dart';
import 'package:path/path.dart' as p;

/// A trimmed clip that was written out.
@immutable
class TrimResult {
  /// Full path of the new clip.
  final String path;

  /// Size of the new clip in bytes.
  final int bytes;

  /// The range that was actually kept, after clamping.
  final TrimRange range;

  const TrimResult({
    required this.path,
    required this.bytes,
    required this.range,
  });

  @override
  String toString() => 'TrimResult($range, $bytes bytes)';
}

/// Cuts a clip down to a chosen range without re-encoding it.
///
/// The cut is a stream copy: Android reads the compressed packets and writes
/// them straight into a new container. Nothing is decoded and nothing is
/// re-encoded, so the trimmed clip looks exactly like the part of the
/// original it came from, and the work takes about as long as copying a
/// file.
///
/// One thing follows from that and is worth knowing: the cut can only start
/// on a key frame, so the real start may sit slightly before the moment the
/// user picked. The alternative would be re-encoding the whole clip, which
/// costs quality and time.
class VideoTrimService {
  final VideoToolsChannel _channel;
  final OutputNamingService _namingService;

  VideoTrimService({
    VideoToolsChannel? channel,
    OutputNamingService namingService = const OutputNamingService(),
  }) : _channel = channel ?? VideoToolsChannel(),
       _namingService = namingService;

  /// Pulls [range] inside a clip of [clipDurationMs] and makes it usable.
  ///
  /// Pure maths, so the rules can be tested on their own: the start never
  /// goes below zero, the end never runs past the clip, and the kept slice
  /// is never shorter than the minimum a container can hold.
  TrimRange clampRange({
    required TrimRange range,
    required int clipDurationMs,
  }) {
    if (clipDurationMs <= 0) return const TrimRange(startMs: 0, endMs: 0);

    final start = range.startMs.clamp(0, clipDurationMs);
    final end = range.endMs.clamp(0, clipDurationMs);

    if (end - start >= AppConstants.trimMinDurationMs) {
      return TrimRange(startMs: start, endMs: end);
    }

    // The chosen slice is too short. Grow it forwards if there is room,
    // otherwise backwards, rather than handing back something unusable.
    final wanted = math.min(AppConstants.trimMinDurationMs, clipDurationMs);
    if (start + wanted <= clipDurationMs) {
      return TrimRange(startMs: start, endMs: start + wanted);
    }
    return TrimRange(
      startMs: math.max(0, clipDurationMs - wanted),
      endMs: clipDurationMs,
    );
  }

  /// Writes the chosen range of [sourcePath] out as a new clip.
  Future<TrimResult> trim({
    required String sourcePath,
    required TrimRange range,
    required int clipDurationMs,
  }) async {
    final clamped = clampRange(range: range, clipDurationMs: clipDurationMs);
    if (!clamped.isValid) {
      throw const VideoToolsException(
        'The chosen part of the clip is too short',
      );
    }

    // The container has to stay the same, because the packets are copied
    // across untouched. An unusual extension falls back to MP4, which is
    // what the muxer writes.
    final extension = _containerExtension(sourcePath);

    final targetPath = _namingService.reserveOutputPath(
      sourcePath: sourcePath,
      suffix: AppConstants.trimOutputSuffix,
      extension: extension,
    );

    final written = await _channel.trim(
      sourcePath: sourcePath,
      targetPath: targetPath,
      startMs: clamped.startMs,
      endMs: clamped.endMs,
    );

    return TrimResult(path: targetPath, bytes: written, range: clamped);
  }

  /// The extension the trimmed clip should carry.
  String _containerExtension(String sourcePath) {
    final extension = p
        .extension(sourcePath)
        .replaceFirst('.', '')
        .toLowerCase();
    if (extension == 'mp4' || extension == 'm4v' || extension == '3gp') {
      return extension;
    }
    return 'mp4';
  }
}

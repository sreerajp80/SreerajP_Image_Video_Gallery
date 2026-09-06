import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/convert/image_output_format.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/video/gif_export_options.dart';
import 'package:in_sreerajp_imgvidgal/models/video/trim_range.dart';
import 'package:in_sreerajp_imgvidgal/models/video/video_clip_info.dart';
import 'package:in_sreerajp_imgvidgal/providers/convert_providers.dart';
import 'package:in_sreerajp_imgvidgal/services/video/gif_export_service.dart';
import 'package:in_sreerajp_imgvidgal/services/video/gif_frame_planner.dart';
import 'package:in_sreerajp_imgvidgal/services/video/video_frame_service.dart';
import 'package:in_sreerajp_imgvidgal/services/video/video_tools_channel.dart';
import 'package:in_sreerajp_imgvidgal/services/video/video_trim_service.dart';

/// The native video tools channel.
final videoToolsChannelProvider = Provider<VideoToolsChannel>((ref) {
  return VideoToolsChannel();
});

/// Pure GIF frame timing maths.
final gifFramePlannerProvider = Provider<GifFramePlanner>((ref) {
  return const GifFramePlanner();
});

/// Single frame grabbing and saving.
final videoFrameServiceProvider = Provider<VideoFrameService>((ref) {
  return VideoFrameService(
    channel: ref.watch(videoToolsChannelProvider),
    conversionService: ref.watch(formatConversionServiceProvider),
    namingService: ref.watch(outputNamingServiceProvider),
  );
});

/// Animated GIF export.
final gifExportServiceProvider = Provider<GifExportService>((ref) {
  return GifExportService(
    channel: ref.watch(videoToolsChannelProvider),
    planner: ref.watch(gifFramePlannerProvider),
    namingService: ref.watch(outputNamingServiceProvider),
  );
});

/// Lossless stream-copy trimming.
final videoTrimServiceProvider = Provider<VideoTrimService>((ref) {
  return VideoTrimService(
    channel: ref.watch(videoToolsChannelProvider),
    namingService: ref.watch(outputNamingServiceProvider),
  );
});

/// What Android can tell us about one clip.
///
/// A clip the platform cannot read comes back as [VideoClipInfo.unknown]
/// rather than an error, and the screen then says the tools are unavailable.
final videoClipInfoProvider = FutureProvider.autoDispose
    .family<VideoClipInfo, MediaItem>((ref, item) async {
      if (!item.isVideo) return VideoClipInfo.unknown;
      try {
        return await ref
            .watch(videoToolsChannelProvider)
            .readClipInfo(item.path);
      } on VideoToolsException {
        return VideoClipInfo.unknown;
      }
    });

/// Where the frame-grab scrubber is sitting, in milliseconds.
final framePositionProvider = StateProvider.autoDispose<int>((ref) => 0);

/// The picture format a grabbed frame is saved in.
final frameFormatProvider = StateProvider.autoDispose<ImageOutputFormat>((ref) {
  return ImageOutputFormat.jpeg;
});

/// Everything one frame preview needs, as a single comparable key.
@immutable
class FramePreviewRequest {
  final String path;
  final int positionMs;

  const FramePreviewRequest({required this.path, required this.positionMs});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FramePreviewRequest &&
          runtimeType == other.runtimeType &&
          path == other.path &&
          positionMs == other.positionMs;

  @override
  int get hashCode => Object.hash(path, positionMs);
}

/// The frame under the scrubber, or null when it cannot be read.
final framePreviewProvider = FutureProvider.autoDispose
    .family<Uint8List?, FramePreviewRequest>((ref, request) async {
      try {
        return await ref
            .watch(videoFrameServiceProvider)
            .previewFrame(
              sourcePath: request.path,
              positionMs: request.positionMs,
            );
      } on VideoToolsException {
        // Clips often refuse a frame near the very end. Showing the last
        // good picture is better than showing an error for a normal case.
        return null;
      }
    });

/// The GIF settings for the clip on screen.
class GifOptionsNotifier extends StateNotifier<GifExportOptions> {
  GifOptionsNotifier({required int clipDurationMs})
    : super(
        GifExportOptions(
          range: TrimRange(
            startMs: 0,
            endMs: clipDurationMs < AppConstants.gifMaxDurationMs
                ? clipDurationMs
                : AppConstants.gifMaxDurationMs,
          ),
        ),
      );

  void setFrameRate(int fps) => state = state.copyWith(frameRate: fps);

  void setMaxSide(int pixels) => state = state.copyWith(maxSide: pixels);

  void setLoop(bool loop) => state = state.copyWith(loop: loop);

  void setRange(TrimRange range) => state = state.copyWith(range: range);
}

/// GIF settings, seeded from the clip's own length.
final gifOptionsProvider = StateNotifierProvider.autoDispose
    .family<GifOptionsNotifier, GifExportOptions, int>((ref, clipDurationMs) {
      return GifOptionsNotifier(clipDurationMs: clipDurationMs);
    });

/// The part of the clip the trim tab will keep.
final trimRangeProvider = StateNotifierProvider.autoDispose
    .family<TrimRangeNotifier, TrimRange, int>((ref, clipDurationMs) {
      return TrimRangeNotifier(clipDurationMs: clipDurationMs);
    });

/// Holds the trim handles and keeps them in a sensible order.
class TrimRangeNotifier extends StateNotifier<TrimRange> {
  final int _clipDurationMs;

  TrimRangeNotifier({required int clipDurationMs})
    : _clipDurationMs = clipDurationMs,
      super(TrimRange.whole(clipDurationMs));

  /// Moves the start handle, never past the end handle.
  void setStart(int startMs) {
    final limit = state.endMs - AppConstants.trimMinDurationMs;
    state = state.copyWith(startMs: startMs.clamp(0, limit < 0 ? 0 : limit));
  }

  /// Moves the end handle, never before the start handle.
  void setEnd(int endMs) {
    final floor = state.startMs + AppConstants.trimMinDurationMs;
    state = state.copyWith(
      endMs: endMs.clamp(
        floor > _clipDurationMs ? _clipDurationMs : floor,
        _clipDurationMs,
      ),
    );
  }

  void reset() => state = TrimRange.whole(_clipDurationMs);
}

/// How far along a video job is.
@immutable
class VideoJobProgress {
  final int done;
  final int total;

  const VideoJobProgress({required this.done, required this.total});

  /// Share of the work finished, 0 to 1.
  double get fraction => total <= 0 ? 0 : (done / total).clamp(0.0, 1.0);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoJobProgress &&
          runtimeType == other.runtimeType &&
          done == other.done &&
          total == other.total;

  @override
  int get hashCode => Object.hash(done, total);
}

/// Progress of the GIF export currently running, or null when none is.
final gifExportProgressProvider = StateProvider.autoDispose<VideoJobProgress?>(
  (ref) => null,
);

/// What a finished video job produced, described for the screen.
@immutable
class VideoJobOutcome {
  /// Full path of the new file.
  final String path;

  /// Size of the new file in bytes.
  final int bytes;

  const VideoJobOutcome({required this.path, required this.bytes});
}

/// Runs the three video jobs and reports how each one ended.
///
/// The screen never calls a service directly, so a failure always arrives as
/// state rather than as an exception thrown at a widget.
class VideoToolsController extends StateNotifier<AsyncValue<VideoJobOutcome?>> {
  final VideoFrameService _frameService;
  final GifExportService _gifService;
  final VideoTrimService _trimService;
  final void Function(VideoJobProgress?) _reportProgress;

  VideoToolsController({
    required VideoFrameService frameService,
    required GifExportService gifService,
    required VideoTrimService trimService,
    required void Function(VideoJobProgress?) reportProgress,
  }) : _frameService = frameService,
       _gifService = gifService,
       _trimService = trimService,
       _reportProgress = reportProgress,
       super(const AsyncValue<VideoJobOutcome?>.data(null));

  /// Saves the frame under the scrubber as a picture.
  Future<void> saveFrame({
    required String sourcePath,
    required int positionMs,
    required ImageOutputFormat format,
  }) async {
    state = const AsyncValue<VideoJobOutcome?>.loading();
    try {
      final result = await _frameService.saveFrame(
        sourcePath: sourcePath,
        positionMs: positionMs,
        format: format,
      );
      state = AsyncValue<VideoJobOutcome?>.data(
        VideoJobOutcome(path: result.path, bytes: result.bytes),
      );
    } catch (error, stackTrace) {
      state = AsyncValue<VideoJobOutcome?>.error(error, stackTrace);
    }
  }

  /// Exports the chosen slice of the clip as an animated GIF.
  Future<void> exportGif({
    required String sourcePath,
    required GifExportOptions options,
    required int clipDurationMs,
  }) async {
    state = const AsyncValue<VideoJobOutcome?>.loading();
    _reportProgress(const VideoJobProgress(done: 0, total: 0));
    try {
      final result = await _gifService.export(
        sourcePath: sourcePath,
        options: options,
        clipDurationMs: clipDurationMs,
        onProgress: (done, total) {
          if (!mounted) return;
          _reportProgress(VideoJobProgress(done: done, total: total));
        },
      );
      state = AsyncValue<VideoJobOutcome?>.data(
        VideoJobOutcome(path: result.path, bytes: result.bytes),
      );
    } catch (error, stackTrace) {
      state = AsyncValue<VideoJobOutcome?>.error(error, stackTrace);
    } finally {
      _reportProgress(null);
    }
  }

  /// Copies the chosen part of the clip into a new file.
  Future<void> trim({
    required String sourcePath,
    required TrimRange range,
    required int clipDurationMs,
  }) async {
    state = const AsyncValue<VideoJobOutcome?>.loading();
    try {
      final result = await _trimService.trim(
        sourcePath: sourcePath,
        range: range,
        clipDurationMs: clipDurationMs,
      );
      state = AsyncValue<VideoJobOutcome?>.data(
        VideoJobOutcome(path: result.path, bytes: result.bytes),
      );
    } catch (error, stackTrace) {
      state = AsyncValue<VideoJobOutcome?>.error(error, stackTrace);
    }
  }

  /// Clears the result so the screen stops showing the last message.
  void clear() => state = const AsyncValue<VideoJobOutcome?>.data(null);
}

/// Controller the video tools screen talks to.
final videoToolsControllerProvider =
    StateNotifierProvider.autoDispose<
      VideoToolsController,
      AsyncValue<VideoJobOutcome?>
    >((ref) {
      return VideoToolsController(
        frameService: ref.watch(videoFrameServiceProvider),
        gifService: ref.watch(gifExportServiceProvider),
        trimService: ref.watch(videoTrimServiceProvider),
        reportProgress: (progress) =>
            ref.read(gifExportProgressProvider.notifier).state = progress,
      );
    });

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/video/gif_export_options.dart';
import 'package:in_sreerajp_imgvidgal/services/convert/output_naming_service.dart';
import 'package:in_sreerajp_imgvidgal/services/video/gif_frame_planner.dart';
import 'package:in_sreerajp_imgvidgal/services/video/video_tools_channel.dart';

/// A GIF that was written out of a clip.
@immutable
class GifExportResult {
  /// Full path of the new GIF.
  final String path;

  /// Size of the GIF in bytes.
  final int bytes;

  /// How many frames it holds.
  final int frameCount;

  const GifExportResult({
    required this.path,
    required this.bytes,
    required this.frameCount,
  });

  @override
  String toString() => 'GifExportResult($frameCount frames, $bytes bytes)';
}

/// What one GIF encode needs, in a shape that can cross into an isolate.
@immutable
class GifEncodeJob {
  /// Each frame as JPEG bytes, in play order.
  final List<Uint8List> frames;

  /// Longest side of the finished GIF.
  final int maxSide;

  /// Gap between frames in milliseconds.
  final int frameDelayMs;

  /// Whether the GIF plays over and over.
  final bool loop;

  const GifEncodeJob({
    required this.frames,
    required this.maxSide,
    required this.frameDelayMs,
    required this.loop,
  });
}

/// Turns a slice of a video into an animated GIF.
///
/// The frames come from Android one at a time, already shrunk, so the app
/// never holds a full-resolution copy of the clip. The encode itself runs on
/// a background isolate, because a hundred-frame GIF takes long enough that
/// the screen would otherwise freeze.
class GifExportService {
  final VideoToolsChannel _channel;
  final GifFramePlanner _planner;
  final OutputNamingService _namingService;

  GifExportService({
    VideoToolsChannel? channel,
    GifFramePlanner planner = const GifFramePlanner(),
    OutputNamingService namingService = const OutputNamingService(),
  }) : _channel = channel ?? VideoToolsChannel(),
       _planner = planner,
       _namingService = namingService;

  /// Exports a GIF from [sourcePath] and saves it beside the clip.
  ///
  /// [onProgress] is called after each frame is pulled, so the screen can
  /// show how far along the export is.
  Future<GifExportResult> export({
    required String sourcePath,
    required GifExportOptions options,
    required int clipDurationMs,
    void Function(int done, int total)? onProgress,
  }) async {
    final times = _planner.plan(
      options: options,
      clipDurationMs: clipDurationMs,
    );
    if (times.isEmpty) {
      throw const VideoToolsException('There is nothing to turn into a GIF');
    }

    final frames = <Uint8List>[];
    for (var index = 0; index < times.length; index++) {
      try {
        frames.add(
          await _channel.grabFrame(
            path: sourcePath,
            positionMs: times[index],
            maxSide: options.effectiveMaxSide,
          ),
        );
      } catch (_) {
        // A clip can refuse a frame near its very end. Losing one frame is
        // far better than losing the whole GIF, so it is simply skipped.
      }
      onProgress?.call(index + 1, times.length);
    }

    if (frames.isEmpty) {
      throw const VideoToolsException('No frames could be read from this clip');
    }

    final bytes = await compute(
      _encodeEntryPoint,
      GifEncodeJob(
        frames: frames,
        maxSide: options.effectiveMaxSide,
        frameDelayMs: options.frameDelayMs,
        loop: options.loop,
      ),
    );

    final file = await _namingService.saveBytes(
      sourcePath: sourcePath,
      suffix: AppConstants.gifOutputSuffix,
      extension: 'gif',
      bytes: bytes,
    );

    return GifExportResult(
      path: file.path,
      bytes: bytes.length,
      frameCount: frames.length,
    );
  }

  /// Encodes the frames on the calling thread.
  ///
  /// Used by the isolate entry point and by the tests.
  static Uint8List encode(GifEncodeJob job) {
    // A GIF delay is counted in hundredths of a second, so anything under
    // 10 ms would round to nothing and play as fast as the viewer can.
    final delayCentiseconds = (job.frameDelayMs / 10).round().clamp(1, 255);

    final encoder = img.GifEncoder(
      repeat: job.loop ? 0 : 1,
      delay: delayCentiseconds,
    );

    var added = 0;
    for (final frameBytes in job.frames) {
      final decoded = _decodeFrame(frameBytes);
      if (decoded == null) continue;
      encoder.addFrame(_fitWithin(decoded, job.maxSide));
      added++;
    }

    if (added == 0) {
      throw const VideoToolsException('None of the frames could be read');
    }

    final bytes = encoder.finish();
    if (bytes == null || bytes.isEmpty) {
      throw const VideoToolsException('The GIF could not be created');
    }
    return bytes;
  }

  /// Decodes one frame, or gives null when it cannot be read.
  static img.Image? _decodeFrame(Uint8List bytes) {
    try {
      return img.decodeImage(bytes);
    } catch (_) {
      return null;
    }
  }

  /// Shrinks a frame so its longest side is no more than [maxSide].
  static img.Image _fitWithin(img.Image image, int maxSide) {
    final longest = image.width > image.height ? image.width : image.height;
    if (longest <= maxSide || longest == 0) return image;

    final scale = maxSide / longest;
    return img.copyResize(
      image,
      width: (image.width * scale).round().clamp(1, maxSide),
      height: (image.height * scale).round().clamp(1, maxSide),
      interpolation: img.Interpolation.average,
    );
  }
}

/// The isolate entry point. It must be a top level function.
Uint8List _encodeEntryPoint(GifEncodeJob job) => GifExportService.encode(job);

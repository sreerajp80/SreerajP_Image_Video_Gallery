import 'package:flutter/services.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/video/video_clip_info.dart';

/// Thrown when a video tool cannot finish its job.
///
/// Damaged clips, formats the device cannot demux, and files that have been
/// deleted since the scan all arrive here. The screen turns it into a
/// message; it never takes the app down.
class VideoToolsException implements Exception {
  final String message;

  const VideoToolsException(this.message);

  @override
  String toString() => 'VideoToolsException: $message';
}

/// Dart side of the native video tools channel.
///
/// Video work cannot be done in Dart, and the project allows no video
/// processing package, so all three jobs use Android's own APIs:
/// `MediaMetadataRetriever` for clip facts and single frames, and
/// `MediaExtractor` with `MediaMuxer` for a trim that copies the compressed
/// packets across without re-encoding them.
class VideoToolsChannel {
  final MethodChannel _channel;

  VideoToolsChannel({MethodChannel? channel})
    : _channel =
          channel ?? const MethodChannel(AppConstants.videoToolsChannelName);

  /// Reads the length, size, rotation, and frame rate of a clip.
  Future<VideoClipInfo> readClipInfo(String path) async {
    final map = await _invoke<Map<Object?, Object?>>('readClipInfo', {
      'path': path,
    });
    if (map == null) return VideoClipInfo.unknown;
    return VideoClipInfo.fromMap(Map<String, dynamic>.from(map));
  }

  /// Pulls one frame out of a clip as JPEG bytes.
  ///
  /// [positionMs] is where in the clip to look. The frame returned is the
  /// closest one the device can give, which for most clips is the nearest
  /// key frame rather than the exact millisecond.
  ///
  /// [maxSide] shrinks the frame before it crosses the channel, which keeps
  /// a 4K clip from sending 8 megabytes per frame during a GIF export.
  Future<Uint8List> grabFrame({
    required String path,
    required int positionMs,
    required int maxSide,
  }) async {
    final bytes = await _invoke<Uint8List>('grabFrame', {
      'path': path,
      'positionMs': positionMs < 0 ? 0 : positionMs,
      'maxSide': maxSide,
    });
    if (bytes == null || bytes.isEmpty) {
      throw const VideoToolsException('No frame could be read at that point');
    }
    return bytes;
  }

  /// Copies the part of a clip between [startMs] and [endMs] into a new file.
  ///
  /// Nothing is re-encoded, so there is no quality loss. Android starts the
  /// copy at the last key frame at or before [startMs], which is what makes
  /// the operation both lossless and fast.
  ///
  /// Returns the number of bytes written.
  Future<int> trim({
    required String sourcePath,
    required String targetPath,
    required int startMs,
    required int endMs,
  }) async {
    final written = await _invoke<int>('trim', {
      'sourcePath': sourcePath,
      'targetPath': targetPath,
      'startMs': startMs,
      'endMs': endMs,
    });
    if (written == null || written <= 0) {
      throw const VideoToolsException('The trimmed clip came out empty');
    }
    return written;
  }

  /// Runs one channel call and turns every platform failure into a
  /// [VideoToolsException].
  Future<T?> _invoke<T>(String method, Map<String, dynamic> arguments) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      throw const VideoToolsException(
        'Video tools are not available on this device',
      );
    } on PlatformException catch (error) {
      throw VideoToolsException(error.message ?? error.code);
    }
  }
}

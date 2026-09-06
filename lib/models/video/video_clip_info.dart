import 'package:flutter/foundation.dart';

/// What Android could tell us about a video file.
///
/// Every field can be missing, because a damaged or unusual clip may report
/// nothing at all. Callers must cope with zeros rather than assume a value.
@immutable
class VideoClipInfo {
  /// Length of the clip in milliseconds, or 0 when unknown.
  final int durationMs;

  /// Stored pixel width, before rotation is applied.
  final int width;

  /// Stored pixel height, before rotation is applied.
  final int height;

  /// Rotation Android says to apply on playback: 0, 90, 180, or 270.
  final int rotationDegrees;

  /// Frames per second, or 0 when the clip does not say.
  final double frameRate;

  /// Whether the file carries a sound track.
  final bool hasAudio;

  const VideoClipInfo({
    this.durationMs = 0,
    this.width = 0,
    this.height = 0,
    this.rotationDegrees = 0,
    this.frameRate = 0,
    this.hasAudio = false,
  });

  /// An empty description, used when the platform says nothing useful.
  static const VideoClipInfo unknown = VideoClipInfo();

  /// Width once rotation is taken into account.
  int get displayWidth =>
      (rotationDegrees == 90 || rotationDegrees == 270) ? height : width;

  /// Height once rotation is taken into account.
  int get displayHeight =>
      (rotationDegrees == 90 || rotationDegrees == 270) ? width : height;

  /// Whether there is enough here to offer the video tools at all.
  bool get isUsable => durationMs > 0;

  factory VideoClipInfo.fromMap(Map<String, dynamic> map) {
    return VideoClipInfo(
      durationMs: (map['durationMs'] as num?)?.toInt() ?? 0,
      width: (map['width'] as num?)?.toInt() ?? 0,
      height: (map['height'] as num?)?.toInt() ?? 0,
      rotationDegrees: (map['rotationDegrees'] as num?)?.toInt() ?? 0,
      frameRate: (map['frameRate'] as num?)?.toDouble() ?? 0,
      hasAudio: map['hasAudio'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'durationMs': durationMs,
    'width': width,
    'height': height,
    'rotationDegrees': rotationDegrees,
    'frameRate': frameRate,
    'hasAudio': hasAudio,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoClipInfo &&
          runtimeType == other.runtimeType &&
          durationMs == other.durationMs &&
          width == other.width &&
          height == other.height &&
          rotationDegrees == other.rotationDegrees &&
          frameRate == other.frameRate &&
          hasAudio == other.hasAudio;

  @override
  int get hashCode => Object.hash(
    durationMs,
    width,
    height,
    rotationDegrees,
    frameRate,
    hasAudio,
  );

  @override
  String toString() =>
      'VideoClipInfo($durationMs ms, ${width}x$height, rot $rotationDegrees)';
}

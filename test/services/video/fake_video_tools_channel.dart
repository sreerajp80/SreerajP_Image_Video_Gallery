import 'dart:io';
import 'dart:typed_data';

import 'package:in_sreerajp_imgvidgal/models/video/video_clip_info.dart';
import 'package:in_sreerajp_imgvidgal/services/video/video_tools_channel.dart';

/// In-memory [VideoToolsChannel] used by tests instead of a real device.
///
/// It records what it was asked for, which is how the tests check that the
/// range clamping and the frame planning reached the platform correctly.
class FakeVideoToolsChannel implements VideoToolsChannel {
  /// What [readClipInfo] reports.
  VideoClipInfo clipInfo;

  /// Bytes returned for every frame; null makes [grabFrame] fail.
  Uint8List? frameBytes;

  /// Bytes written into the target file by [trim].
  Uint8List trimBytes;

  /// Positions [grabFrame] was asked for, in order.
  final List<int> requestedPositions = <int>[];

  /// Longest sides [grabFrame] was asked for, in order.
  final List<int> requestedMaxSides = <int>[];

  /// Ranges [trim] was asked for, as start and end pairs.
  final List<List<int>> requestedTrims = <List<int>>[];

  /// When set, [grabFrame] fails for exactly these positions.
  Set<int> failingPositions = <int>{};

  /// When true, [trim] throws instead of writing anything.
  bool failTrim = false;

  FakeVideoToolsChannel({
    this.clipInfo = const VideoClipInfo(durationMs: 10000),
    this.frameBytes,
    Uint8List? trimBytes,
  }) : trimBytes = trimBytes ?? Uint8List.fromList(<int>[1, 2, 3, 4]);

  @override
  Future<VideoClipInfo> readClipInfo(String path) async => clipInfo;

  @override
  Future<Uint8List> grabFrame({
    required String path,
    required int positionMs,
    required int maxSide,
  }) async {
    requestedPositions.add(positionMs);
    requestedMaxSides.add(maxSide);

    if (failingPositions.contains(positionMs)) {
      throw const VideoToolsException('No frame there');
    }
    final bytes = frameBytes;
    if (bytes == null) {
      throw const VideoToolsException('No frame could be read');
    }
    return bytes;
  }

  @override
  Future<int> trim({
    required String sourcePath,
    required String targetPath,
    required int startMs,
    required int endMs,
  }) async {
    requestedTrims.add(<int>[startMs, endMs]);
    if (failTrim) {
      throw const VideoToolsException('The clip could not be trimmed');
    }

    // The real platform writes the file itself, so the fake does too.
    await File(targetPath).writeAsBytes(trimBytes, flush: true);
    return trimBytes.length;
  }
}

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/convert/conversion_request.dart';
import 'package:in_sreerajp_imgvidgal/models/convert/image_output_format.dart';
import 'package:in_sreerajp_imgvidgal/services/convert/format_conversion_service.dart';
import 'package:in_sreerajp_imgvidgal/services/convert/output_naming_service.dart';
import 'package:in_sreerajp_imgvidgal/services/video/video_tools_channel.dart';

/// A still frame that was saved out of a clip.
@immutable
class FrameGrabResult {
  /// Full path of the new picture.
  final String path;

  /// Size of the new picture in bytes.
  final int bytes;

  /// Where in the clip the frame came from, in milliseconds.
  final int positionMs;

  const FrameGrabResult({
    required this.path,
    required this.bytes,
    required this.positionMs,
  });

  @override
  String toString() => 'FrameGrabResult($positionMs ms, $bytes bytes)';
}

/// Pulls a single frame out of a video and saves it as a picture.
///
/// Android hands the frame back as a JPEG. When the user asks for a PNG it
/// is re-encoded here, which costs one extra pass but keeps the choice of
/// format in the user's hands.
class VideoFrameService {
  final VideoToolsChannel _channel;
  final FormatConversionService _conversionService;
  final OutputNamingService _namingService;

  VideoFrameService({
    VideoToolsChannel? channel,
    FormatConversionService? conversionService,
    OutputNamingService namingService = const OutputNamingService(),
  }) : _channel = channel ?? VideoToolsChannel(),
       _conversionService = conversionService ?? FormatConversionService(),
       _namingService = namingService;

  /// Reads one frame for showing on screen, without saving anything.
  Future<Uint8List> previewFrame({
    required String sourcePath,
    required int positionMs,
  }) {
    return _channel.grabFrame(
      path: sourcePath,
      positionMs: positionMs,
      maxSide: AppConstants.framePreviewMaxSide,
    );
  }

  /// Saves the frame at [positionMs] as a new picture beside the clip.
  Future<FrameGrabResult> saveFrame({
    required String sourcePath,
    required int positionMs,
    ImageOutputFormat format = ImageOutputFormat.jpeg,
  }) async {
    final jpegBytes = await _channel.grabFrame(
      path: sourcePath,
      positionMs: positionMs,
      // Frames are saved at their own resolution, so no shrinking is asked
      // for here; 0 tells Android to keep the native size.
      maxSide: 0,
    );

    var bytes = jpegBytes;
    if (format != ImageOutputFormat.jpeg) {
      final encoded = await _conversionService.convert(
        sourceBytes: jpegBytes,
        request: ConversionRequest(format: format),
      );
      bytes = encoded.bytes;
    }

    final File file = await _namingService.saveBytes(
      sourcePath: sourcePath,
      suffix: AppConstants.frameOutputSuffix,
      extension: format.extension,
      bytes: bytes,
    );

    return FrameGrabResult(
      path: file.path,
      bytes: bytes.length,
      positionMs: positionMs,
    );
  }
}

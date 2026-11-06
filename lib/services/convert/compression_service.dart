import 'dart:typed_data';

import 'package:in_sreerajp_imgvidgal/models/convert/conversion_request.dart';
import 'package:in_sreerajp_imgvidgal/models/convert/size_estimate.dart';
import 'package:in_sreerajp_imgvidgal/services/convert/format_conversion_service.dart';

/// Works out how big a converted copy would be, without writing one.
///
/// The number shown to the user is not a guess: the picture really is
/// encoded at the settings on screen, in the background, and the byte count
/// of that result is what the preview reports. Nothing reaches the disk
/// until Save is pressed.
class CompressionService {
  final FormatConversionService _conversionService;

  CompressionService({FormatConversionService? conversionService})
    : _conversionService = conversionService ?? FormatConversionService();

  /// Encodes [sourceBytes] at [request] and reports the size it came out.
  ///
  /// [originalBytes] is only carried through so the screen can show what was
  /// saved; it takes no part in the encoding.
  Future<SizeEstimate> estimate({
    required Uint8List sourceBytes,
    required ConversionRequest request,
    required int originalBytes,
  }) async {
    final encoded = await _conversionService.convert(
      sourceBytes: sourceBytes,
      request: request,
    );

    return SizeEstimate(
      bytes: encoded.bytes.length,
      width: encoded.width,
      height: encoded.height,
      originalBytes: originalBytes,
    );
  }
}

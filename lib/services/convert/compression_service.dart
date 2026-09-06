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

  /// A short human label for a byte count, such as `2.4 MB`.
  ///
  /// Kept here rather than in a widget so the same rounding is used
  /// everywhere a size is shown, and so it can be tested.
  static String formatBytes(int bytes) {
    if (bytes < 0) return '0 B';
    if (bytes < 1024) return '$bytes B';

    const units = <String>['KB', 'MB', 'GB'];
    var value = bytes / 1024;
    var unitIndex = 0;

    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex++;
    }

    // One decimal place below 10 keeps "1.4 MB" readable while "245 KB"
    // stays free of a pointless ".0".
    final text = value >= 10
        ? value.round().toString()
        : value.toStringAsFixed(1);
    return '$text ${units[unitIndex]}';
  }
}

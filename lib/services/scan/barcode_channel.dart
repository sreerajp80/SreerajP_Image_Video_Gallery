import 'package:flutter/services.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/core/errors/app_exception.dart';
import 'package:in_sreerajp_imgvidgal/services/scan/image_scan_service.dart';

/// Thrown when the barcode reader could not run, as opposed to finding no
/// code. [code] is the reason Kotlin gave, such as `unreadable`.
final class BarcodeDecodeException extends FeatureException {
  final String code;

  const BarcodeDecodeException(this.code, super.message, {super.cause});
}

/// The ZXing barcode reader in Kotlin (`BarcodeChannelHandler`).
///
/// Open source end to end (ZXing core is Apache-2.0) and with no network
/// code. It replaced mobile_scanner, which used Google's ML Kit (G47).
class BarcodeChannel {
  final MethodChannel _channel;

  const BarcodeChannel({
    MethodChannel channel = const MethodChannel(
      AppConstants.barcodeChannelName,
    ),
  }) : _channel = channel;

  /// Every code in the picture at [path], in any supported format.
  ///
  /// An empty list means the picture holds no code. A reader that could not
  /// run throws [BarcodeDecodeException].
  Future<List<RawBarcode>> decodeImageFile(String path) async {
    final raw = await _call('decodeImageFile', <String, Object?>{'path': path});
    return _toBarcodes(raw);
  }

  /// QR codes in one camera frame, given as its brightness (Y) plane.
  ///
  /// [rowStride] is the number of bytes from one row to the next, which can
  /// be larger than [width].
  Future<List<String>> decodeLuminance({
    required Uint8List bytes,
    required int width,
    required int height,
    required int rowStride,
  }) async {
    final raw = await _call('decodeLuminance', <String, Object?>{
      'bytes': bytes,
      'width': width,
      'height': height,
      'rowStride': rowStride,
    });
    return _toBarcodes(raw).map((code) => code.value).toList(growable: false);
  }

  Future<Object?> _call(String method, Map<String, Object?> arguments) async {
    try {
      return await _channel.invokeMethod<Object?>(method, arguments);
    } on PlatformException catch (error) {
      throw BarcodeDecodeException(
        error.code,
        'The barcode reader could not run',
        cause: error,
      );
    } on MissingPluginException catch (error) {
      throw BarcodeDecodeException(
        'missing',
        'The barcode reader is not available',
        cause: error,
      );
    }
  }

  static List<RawBarcode> _toBarcodes(Object? raw) {
    if (raw is! List) return const <RawBarcode>[];
    return <RawBarcode>[
      for (final entry in raw)
        if (entry is Map &&
            entry['value'] is String &&
            (entry['value'] as String).isNotEmpty)
          RawBarcode(
            entry['value'] as String,
            format: formatName(entry['format']?.toString() ?? ''),
          ),
    ];
  }

  /// Turns ZXing's `QR_CODE` into the `qrCode` style the app already uses.
  static String formatName(String zxing) {
    final parts = zxing.toLowerCase().split('_').where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '';
    final first = parts.first;
    final rest = parts.skip(1).map((p) => p[0].toUpperCase() + p.substring(1));
    return first + rest.join();
  }
}

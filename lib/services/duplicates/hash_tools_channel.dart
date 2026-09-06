import 'package:flutter/services.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';

/// Reads fingerprints of a file without pulling the whole thing into memory.
///
/// Both jobs here are things Dart cannot do safely on its own. A SHA-256 over
/// a two gigabyte video would need the whole file in memory if it were read
/// through the normal byte channel, and decoding a 50 megapixel photo just to
/// shrink it to 32x32 would be just as wasteful. Android streams the digest
/// and downsamples the decode, so both stay cheap whatever the file size.
///
/// Injected everywhere, so tests can supply a fake without touching Android.
abstract class HashToolsChannel {
  /// Lower-case hex SHA-256 of the whole file at [uri], or null when the file
  /// cannot be read.
  Future<String?> sha256(String uri);

  /// A [size] by [size] grayscale grid of the picture at [uri], one byte per
  /// pixel, row by row. Null when the file is not a picture the device can
  /// decode.
  Future<Uint8List?> grayscale(String uri, {required int size});
}

/// Real [HashToolsChannel] backed by the Android platform channel.
class PlatformHashToolsChannel implements HashToolsChannel {
  final MethodChannel _channel;

  PlatformHashToolsChannel({MethodChannel? channel})
    : _channel =
          channel ?? const MethodChannel(AppConstants.hashToolsChannelName);

  @override
  Future<String?> sha256(String uri) async {
    if (uri.isEmpty) return null;
    return _invoke<String>('sha256', <String, Object?>{
      'uri': uri,
      'blockSize': AppConstants.duplicateHashBlockBytes,
    });
  }

  @override
  Future<Uint8List?> grayscale(String uri, {required int size}) async {
    if (uri.isEmpty || size <= 0) return null;
    final bytes = await _invoke<Uint8List>('grayscale', <String, Object?>{
      'uri': uri,
      'size': size,
    });
    // A short buffer means the decode went wrong on the far side; treating it
    // as "no picture" is safer than hashing whatever arrived.
    if (bytes == null || bytes.length != size * size) return null;
    return bytes;
  }

  /// Runs a channel call, turning every failure into a null.
  ///
  /// A duplicate scan walks thousands of files and will meet broken ones. A
  /// single unreadable file has to be a skipped row, never an exception that
  /// ends the whole scan, so nothing is rethrown here.
  Future<T?> _invoke<T>(String method, Map<String, Object?> arguments) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      // Running on a host or in a test with no Android side attached.
      return null;
    }
  }
}

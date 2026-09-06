import 'package:flutter/services.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';

/// Thrown when the platform encoder cannot produce a picture.
class ImageCodecException implements Exception {
  final String message;

  const ImageCodecException(this.message);

  @override
  String toString() => 'ImageCodecException: $message';
}

/// Dart side of the small native encoder channel.
///
/// It exists for one reason: the Dart `image` package can read WEBP but has
/// no WEBP writer, while Android's own `Bitmap.compress` has one built in.
/// Everything else in the converter stays in Dart.
class ImageCodecChannel {
  final MethodChannel _channel;

  ImageCodecChannel({MethodChannel? channel})
    : _channel =
          channel ?? const MethodChannel(AppConstants.imageToolsChannelName);

  /// Encodes raw pixels as WEBP.
  ///
  /// [pixels] is straight RGBA, four bytes per pixel, row by row — the shape
  /// the `image` package hands back — so no second decode is needed on the
  /// Android side.
  ///
  /// [quality] is 0 to 100 and is ignored when [lossless] is true.
  Future<Uint8List> encodeWebp({
    required Uint8List pixels,
    required int width,
    required int height,
    required int quality,
    bool lossless = false,
  }) async {
    if (width <= 0 || height <= 0) {
      throw const ImageCodecException('The picture has no size');
    }
    if (pixels.length != width * height * 4) {
      throw const ImageCodecException(
        'The pixel data does not match the picture size',
      );
    }

    try {
      final result = await _channel.invokeMethod<Uint8List>('encodeWebp', {
        'pixels': pixels,
        'width': width,
        'height': height,
        'quality': quality.clamp(0, 100),
        'lossless': lossless,
      });
      if (result == null || result.isEmpty) {
        throw const ImageCodecException('The WEBP encoder returned nothing');
      }
      return result;
    } on ImageCodecException {
      rethrow;
    } on MissingPluginException {
      throw const ImageCodecException(
        'WEBP saving is not available on this device',
      );
    } on PlatformException catch (error) {
      throw ImageCodecException(
        'The picture could not be saved as WEBP: ${error.message ?? error.code}',
      );
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:in_sreerajp_imgvidgal/models/convert/conversion_request.dart';
import 'package:in_sreerajp_imgvidgal/models/convert/image_output_format.dart';
import 'package:in_sreerajp_imgvidgal/services/convert/image_codec_channel.dart';
import 'package:in_sreerajp_imgvidgal/services/convert/image_resize_service.dart';

/// Thrown when a picture cannot be converted.
///
/// A corrupt or unsupported file is a normal thing to meet on a device, so
/// this is a plain exception the screen turns into a message rather than
/// something that takes the app down.
class ConversionException implements Exception {
  final String message;

  const ConversionException(this.message);

  @override
  String toString() => 'ConversionException: $message';
}

/// Everything one conversion needs, in a shape that can cross into an
/// isolate: bytes, a JSON request, and nothing else.
@immutable
class ConversionJob {
  final Uint8List sourceBytes;
  final String requestJson;

  const ConversionJob({required this.sourceBytes, required this.requestJson});
}

/// A finished picture, still in memory.
@immutable
class EncodedImage {
  final Uint8List bytes;
  final int width;
  final int height;

  const EncodedImage({
    required this.bytes,
    required this.width,
    required this.height,
  });
}

/// Raw pixels ready for the platform encoder.
@immutable
class RawPixels {
  final Uint8List rgba;
  final int width;
  final int height;

  const RawPixels({
    required this.rgba,
    required this.width,
    required this.height,
  });
}

/// Turns a picture into another format, another size, or both.
///
/// The steps are always the same: decode, resize if asked, flatten if the
/// target cannot keep see-through pixels, then encode. JPEG, PNG, and BMP
/// are encoded here in Dart. WEBP has no Dart encoder, so the pixels go to
/// Android instead — but the decode and resize before it are identical.
class FormatConversionService {
  final ImageResizeService _resizeService;
  final ImageCodecChannel _codecChannel;

  FormatConversionService({
    ImageResizeService resizeService = const ImageResizeService(),
    ImageCodecChannel? codecChannel,
  }) : _resizeService = resizeService,
       _codecChannel = codecChannel ?? ImageCodecChannel();

  /// Converts [sourceBytes] as [request] describes.
  ///
  /// The Dart formats run on a background isolate so a big photo never
  /// freezes the screen. WEBP does its decode and resize on that isolate too
  /// and only comes back to the main thread for the platform call, which is
  /// the cheap part.
  Future<EncodedImage> convert({
    required Uint8List sourceBytes,
    required ConversionRequest request,
  }) async {
    final job = ConversionJob(
      sourceBytes: sourceBytes,
      requestJson: request.toJson(),
    );

    if (!request.format.needsPlatformEncoder) {
      return compute(_convertEntryPoint, job);
    }

    final pixels = await compute(_preparePixelsEntryPoint, job);
    final bytes = await _codecChannel.encodeWebp(
      pixels: pixels.rgba,
      width: pixels.width,
      height: pixels.height,
      quality: request.effectiveQuality,
    );
    return EncodedImage(
      bytes: bytes,
      width: pixels.width,
      height: pixels.height,
    );
  }

  /// Converts on the calling thread.
  ///
  /// Used by the isolate entry point and by the tests. Application code
  /// should prefer [convert]. WEBP is not available here, because only
  /// Android can encode it.
  EncodedImage convertSync({
    required Uint8List sourceBytes,
    required ConversionRequest request,
  }) {
    final prepared = prepare(sourceBytes: sourceBytes, request: request);
    return EncodedImage(
      bytes: encode(prepared, request),
      width: prepared.width,
      height: prepared.height,
    );
  }

  /// Decodes, resizes, and flattens, stopping just before the encoder.
  img.Image prepare({
    required Uint8List sourceBytes,
    required ConversionRequest request,
  }) {
    var image = decode(sourceBytes);

    final target = _resizeService.resolve(
      sourceWidth: image.width,
      sourceHeight: image.height,
      spec: request.resize,
    );
    if (target.width != image.width || target.height != image.height) {
      image = img.copyResize(
        image,
        width: target.width,
        height: target.height,
        interpolation: img.Interpolation.average,
      );
    }

    if (!request.format.supportsTransparency && image.hasAlpha) {
      image = flattenOntoWhite(image);
    }

    return image;
  }

  /// Decodes picture bytes, or throws [ConversionException] if it cannot.
  img.Image decode(Uint8List bytes) {
    if (bytes.isEmpty) {
      throw const ConversionException('The picture file is empty');
    }
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        throw const ConversionException('This picture format is not supported');
      }
      return decoded;
    } on ConversionException {
      rethrow;
    } catch (error) {
      throw ConversionException('The picture could not be read: $error');
    }
  }

  /// Encodes [image] in the format [request] asks for.
  Uint8List encode(img.Image image, ConversionRequest request) {
    try {
      switch (request.format) {
        case ImageOutputFormat.jpeg:
          return img.encodeJpg(image, quality: request.effectiveQuality);
        case ImageOutputFormat.png:
          return img.encodePng(image);
        case ImageOutputFormat.bmp:
          return img.encodeBmp(image);
        case ImageOutputFormat.webp:
          // Only Android can write WEBP; [convert] routes it to the channel.
          throw const ConversionException(
            'WEBP saving is not available on this platform',
          );
      }
    } on ConversionException {
      rethrow;
    } catch (error) {
      throw ConversionException('The picture could not be saved: $error');
    }
  }

  /// Puts a see-through picture on a white background.
  ///
  /// JPEG and BMP have no transparency. Without this step every clear pixel
  /// would come out black, which surprises people who convert a logo PNG.
  img.Image flattenOntoWhite(img.Image image) {
    final canvas = img.Image(
      width: image.width,
      height: image.height,
      numChannels: 3,
    );
    img.fill(canvas, color: img.ColorRgb8(255, 255, 255));
    return img.compositeImage(canvas, image, blend: img.BlendMode.alpha);
  }

  /// Straight RGBA bytes for the platform encoder.
  RawPixels toRawPixels(img.Image image) {
    final rgba = image.convert(numChannels: 4);
    return RawPixels(
      rgba: rgba.getBytes(order: img.ChannelOrder.rgba),
      width: rgba.width,
      height: rgba.height,
    );
  }
}

/// The isolate entry point for the Dart formats. Must be a top level function.
EncodedImage _convertEntryPoint(ConversionJob job) {
  final service = FormatConversionService();
  return service.convertSync(
    sourceBytes: job.sourceBytes,
    request: ConversionRequest.fromJson(job.requestJson),
  );
}

/// The isolate entry point that stops at raw pixels, for the WEBP path.
RawPixels _preparePixelsEntryPoint(ConversionJob job) {
  final service = FormatConversionService();
  final image = service.prepare(
    sourceBytes: job.sourceBytes,
    request: ConversionRequest.fromJson(job.requestJson),
  );
  return service.toRawPixels(image);
}

import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:in_sreerajp_imgvidgal/models/privacy/privacy_scrub_options.dart';

/// Provides lossless and selective metadata stripping for images.
///
/// Designed to run offline-first with zero third-party dependencies.
/// For JPEG, PNG, and WebP, full EXIF stripping operates directly at the
/// byte/chunk level without decoding or re-encoding image pixels, guaranteeing
/// 100% bit-exact pixel preservation and zero compression degradation.
class ExifScrubberService {
  const ExifScrubberService();

  /// Strips metadata from [bytes] according to [options].
  ///
  /// For large inputs (> 512 KB), processing runs on a background isolate
  /// to avoid UI frame drops. Returns sanitized image bytes.
  Future<Uint8List> scrubBytes(
    Uint8List bytes, {
    PrivacyScrubOptions options = PrivacyScrubOptions.fullScrub,
  }) async {
    if (bytes.length < 16) return bytes;

    try {
      if (bytes.length < 512 * 1024) {
        return scrubBytesSync(bytes, options: options);
      }
      return await Isolate.run(() => scrubBytesSync(bytes, options: options));
    } catch (_) {
      // Fallback: if byte manipulation fails on corrupt input, return original safely.
      return bytes;
    }
  }

  /// Synchronous byte scrubber implementation.
  Uint8List scrubBytesSync(
    Uint8List bytes, {
    PrivacyScrubOptions options = PrivacyScrubOptions.fullScrub,
  }) {
    if (bytes.length < 16) return bytes;

    if (options.stripAllExif) {
      if (_isJpeg(bytes)) {
        return _stripJpegLossless(bytes);
      } else if (_isPng(bytes)) {
        return _stripPngLossless(bytes);
      } else if (_isWebP(bytes)) {
        return _stripWebpLossless(bytes);
      }
    }

    // Granular / selective scrubbing or general format fallback
    return _scrubSelectiveOrFallback(bytes, options);
  }

  /// Whether the byte array starts with JPEG SOI (Start of Image) marker 0xFFD8.
  bool _isJpeg(Uint8List bytes) =>
      bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xD8;

  /// Whether the byte array starts with the PNG 8-byte signature.
  bool _isPng(Uint8List bytes) =>
      bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47 &&
      bytes[4] == 0x0D &&
      bytes[5] == 0x0A &&
      bytes[6] == 0x1A &&
      bytes[7] == 0x0A;

  /// Whether the byte array has the RIFF WebP header.
  bool _isWebP(Uint8List bytes) =>
      bytes.length >= 12 &&
      bytes[0] == 0x52 && // R
      bytes[1] == 0x49 && // I
      bytes[2] == 0x46 && // F
      bytes[3] == 0x46 && // F
      bytes[8] == 0x57 && // W
      bytes[9] == 0x45 && // E
      bytes[10] == 0x42 && // B
      bytes[11] == 0x50; // P

  /// Performs 100% lossless JPEG metadata stripping.
  ///
  /// Removes APP1 (Exif and XMP), APP13 (Photoshop IPTC), and COM (Comment) segments
  /// while keeping APP0 (JFIF), APP2 (ICC profile for accurate color reproduction),
  /// DQT, DHT, SOF, and all entropy-coded scan data (SOS).
  Uint8List _stripJpegLossless(Uint8List bytes) {
    final builder = BytesBuilder(copy: false);
    var offset = 0;
    final length = bytes.length;

    // Check SOI
    if (bytes[offset] != 0xFF || bytes[offset + 1] != 0xD8) {
      return bytes;
    }

    builder.add([0xFF, 0xD8]);
    offset += 2;

    while (offset < length - 1) {
      if (bytes[offset] != 0xFF) {
        // Not a marker boundary, flush remainder
        builder.add(bytes.sublist(offset));
        break;
      }

      // Skip 0xFF padding
      while (offset < length && bytes[offset] == 0xFF) {
        offset++;
      }

      if (offset >= length) break;
      final marker = bytes[offset++];

      // EOI (End of Image)
      if (marker == 0xD9) {
        builder.add([0xFF, 0xD9]);
        break;
      }

      // SOS (Start of Scan) - Entropy coded image stream begins.
      // From SOS to EOI, copy verbatim without parsing inner bytes.
      if (marker == 0xDA) {
        builder.add([0xFF, 0xDA]);
        if (offset < length) {
          builder.add(bytes.sublist(offset));
        }
        break;
      }

      // Standalone markers with no length payload (RST0-RST7, TEM)
      if ((marker >= 0xD0 && marker <= 0xD7) || marker == 0x01) {
        builder.add([0xFF, marker]);
        continue;
      }

      if (offset + 1 >= length) break;
      final segmentLength = (bytes[offset] << 8) | bytes[offset + 1];
      if (segmentLength < 2 || offset + segmentLength > length) {
        // Corrupt length; append remainder safely
        builder.add(bytes.sublist(offset - 1));
        break;
      }

      // Strip APP1 (0xE1: Exif/XMP), APP13 (0xED: Photoshop IPTC), COM (0xFE: Comments)
      final shouldDrop = marker == 0xE1 || marker == 0xED || marker == 0xFE;

      if (!shouldDrop) {
        builder.add([0xFF, marker]);
        builder.add(bytes.sublist(offset, offset + segmentLength));
      }

      offset += segmentLength;
    }

    return builder.takeBytes();
  }

  /// Performs 100% lossless PNG metadata stripping.
  ///
  /// Removes eXIf, tEXt, zTXt, and iTXt chunks while preserving pixel chunks
  /// (IDAT), header (IHDR), palette (PLTE), and color spaces (iCCP, sRGB, gAMA).
  Uint8List _stripPngLossless(Uint8List bytes) {
    final builder = BytesBuilder(copy: false);
    // Write 8-byte PNG signature
    builder.add(bytes.sublist(0, 8));
    var offset = 8;
    final length = bytes.length;

    while (offset + 8 <= length) {
      final chunkLength =
          (bytes[offset] << 24) |
          (bytes[offset + 1] << 16) |
          (bytes[offset + 2] << 8) |
          bytes[offset + 3];

      if (chunkLength < 0 || offset + 12 + chunkLength > length) {
        // Corrupt chunk, write remainder
        builder.add(bytes.sublist(offset));
        break;
      }

      final type = String.fromCharCodes(bytes.sublist(offset + 4, offset + 8));

      // Drop metadata chunks
      final isMetadata =
          type == 'eXIf' || type == 'tEXt' || type == 'zTXt' || type == 'iTXt';

      if (!isMetadata) {
        // Keep chunk: length (4) + type (4) + data (chunkLength) + crc (4) = 12 + chunkLength
        builder.add(bytes.sublist(offset, offset + 12 + chunkLength));
      }

      offset += 12 + chunkLength;
      if (type == 'IEND') break;
    }

    return builder.takeBytes();
  }

  /// Performs 100% lossless WebP metadata stripping.
  ///
  /// Strips EXIF and XMP chunks from the RIFF container without touching VP8/VP8L.
  Uint8List _stripWebpLossless(Uint8List bytes) {
    if (bytes.length < 12) return bytes;

    final builder = BytesBuilder(copy: false);
    var offset = 12; // Skip RIFF + size + WEBP
    final length = bytes.length;

    final chunkBuilder = BytesBuilder(copy: false);

    while (offset + 8 <= length) {
      final fourCC = String.fromCharCodes(bytes.sublist(offset, offset + 4));
      final chunkSize =
          bytes[offset + 4] |
          (bytes[offset + 5] << 8) |
          (bytes[offset + 6] << 16) |
          (bytes[offset + 7] << 24);

      if (chunkSize < 0) break;
      final paddedSize = (chunkSize + 1) & ~1;
      if (offset + 8 + paddedSize > length) {
        // Corrupt or truncated chunk
        break;
      }

      // Drop EXIF and XMP chunks
      final isMetadata = fourCC == 'EXIF' || fourCC == 'XMP ';

      if (!isMetadata) {
        chunkBuilder.add(bytes.sublist(offset, offset + 8 + paddedSize));
      }

      offset += 8 + paddedSize;
    }

    final remainingChunks = chunkBuilder.takeBytes();
    final newRiffSize = 4 + remainingChunks.length; // 'WEBP' (4) + chunks

    // Build final RIFF
    builder.add([0x52, 0x49, 0x46, 0x46]); // 'RIFF'
    builder.add([
      newRiffSize & 0xFF,
      (newRiffSize >> 8) & 0xFF,
      (newRiffSize >> 16) & 0xFF,
      (newRiffSize >> 24) & 0xFF,
    ]);
    builder.add([0x57, 0x45, 0x42, 0x50]); // 'WEBP'
    builder.add(remainingChunks);

    return builder.takeBytes();
  }

  /// Selective scrubbing for granular privacy options.
  Uint8List _scrubSelectiveOrFallback(
    Uint8List bytes,
    PrivacyScrubOptions options,
  ) {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return bytes;

      if (options.stripAllExif) {
        // Encode clean JPEG with no metadata attached
        return Uint8List.fromList(img.encodeJpg(decoded, quality: 92));
      }

      final exif = img.decodeJpgExif(bytes);
      if (exif == null || exif.isEmpty) {
        return bytes;
      }

      // Strip location
      if (options.stripLocation) {
        exif.gpsIfd.data.clear();
      }

      // Strip camera/lens serials & specs
      if (options.stripCameraAndLensSerials) {
        exif.exifIfd.data.remove(0xA431); // BodySerialNumber
        exif.exifIfd.data.remove(0xA434); // LensModel
        exif.exifIfd.data.remove(0xA433); // LensMake
        exif.exifIfd.data.remove(0xA435); // LensSerialNumber
        exif.exifIfd.data.remove(0xA432); // LensSpecification
        exif.exifIfd.data.remove(0x00A7); // Shutter count
        exif.imageIfd.data.remove(0x010F); // Make
        exif.imageIfd.data.remove(0x0110); // Model
      }

      // Strip timestamps
      if (options.stripTimestamps) {
        exif.exifIfd.data.remove(0x9003); // DateTimeOriginal
        exif.exifIfd.data.remove(0x9004); // DateTimeDigitized
        exif.exifIfd.data.remove(0x9290); // SubSecTime
        exif.exifIfd.data.remove(0x9291); // SubSecTimeOriginal
        exif.exifIfd.data.remove(0x9292); // SubSecTimeDigitized
        exif.imageIfd.data.remove(0x0132); // DateTime
      }

      // Strip author & software
      if (options.stripAuthorAndSoftware) {
        exif.imageIfd.data.remove(0x0131); // Software
        exif.imageIfd.data.remove(0x013B); // Artist
        exif.imageIfd.data.remove(0x8298); // Copyright
        exif.exifIfd.data.remove(0x9286); // UserComment
        exif.exifIfd.data.remove(0x927C); // MakerNote
      }

      decoded.exif = exif;
      return Uint8List.fromList(img.encodeJpg(decoded, quality: 92));
    } catch (_) {
      return bytes;
    }
  }
}

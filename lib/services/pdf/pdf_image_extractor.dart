import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/pdf/pdf_extraction_result.dart';
import 'package:in_sreerajp_imgvidgal/models/pdf/pdf_image_entry.dart';
import 'package:in_sreerajp_imgvidgal/services/pdf/pdf_lexer.dart';

/// Pulls the pictures out of a PDF.
///
/// Pure: bytes in, entries out, no file system and no platform channel. That
/// is what lets the awkward cases be tested with hand-built files.
///
/// A PDF is untrusted input. Every size it declares is checked before a byte
/// is allocated for it, every decode is wrapped, and nothing here throws: a
/// file that cannot be read comes back as a refusal, and an image that cannot
/// be decoded comes back listed with its reason.
class PdfImageExtractor {
  const PdfImageExtractor();

  /// Reads [bytes] and returns every image object it found.
  PdfExtractionResult extract(Uint8List bytes) {
    if (bytes.length > AppConstants.pdfExtractMaxFileBytes) {
      return const PdfExtractionResult.refused(PdfRefusalReason.fileTooLarge);
    }
    if (bytes.isEmpty) {
      return const PdfExtractionResult.refused(PdfRefusalReason.notAPdf);
    }

    final lexer = PdfLexer(bytes);
    if (!lexer.hasPdfHeader) {
      return const PdfExtractionResult.refused(PdfRefusalReason.notAPdf);
    }

    final List<PdfObject> objects;
    try {
      objects = lexer.readObjects();
    } catch (_) {
      // The lexer is written not to throw, but a file crafted to break it
      // must still end in a message rather than a crash. Hard rule 5.
      return const PdfExtractionResult.refused(PdfRefusalReason.unreadable);
    }

    if (objects.isEmpty) {
      return const PdfExtractionResult.refused(PdfRefusalReason.unreadable);
    }

    final byNumber = <int, PdfObject>{
      for (final object in objects) object.number: object,
    };

    if (_isEncrypted(bytes, objects)) {
      return const PdfExtractionResult.refused(PdfRefusalReason.encrypted);
    }

    final entries = <PdfImageEntry>[];
    var truncated = false;

    for (final object in objects) {
      if (!object.hasStream) continue;
      if (!_isImage(object.dictionary)) continue;

      if (entries.length >= AppConstants.pdfExtractMaxImages) {
        truncated = true;
        break;
      }

      entries.add(_readImage(lexer, object, byNumber));
    }

    return PdfExtractionResult(entries: entries, wasTruncated: truncated);
  }

  /// Whether the file says it is encrypted.
  ///
  /// Refused rather than guessed at. Most encrypted PDFs in the wild use the
  /// empty owner password and could technically be opened, but doing that
  /// quietly would be the app deciding on the user's behalf that a lock does
  /// not count.
  bool _isEncrypted(Uint8List bytes, List<PdfObject> objects) {
    for (final object in objects) {
      final dictionary = object.dictionary;
      if (dictionary.containsKey('Encrypt')) return true;
      // The trailer's /Encrypt key is what actually marks a file encrypted,
      // and a cross-reference stream carries it in its own dictionary.
      if (dictionary['Type'] == const PdfName('XRef') &&
          dictionary.containsKey('Encrypt')) {
        return true;
      }
    }
    return _containsTrailerEncrypt(bytes);
  }

  /// Looks for `/Encrypt` in a plain trailer, which is not an object at all.
  bool _containsTrailerEncrypt(Uint8List bytes) {
    const needle = <int>[
      0x2F, 0x45, 0x6E, 0x63, 0x72, 0x79, 0x70, 0x74, // /Encrypt
    ];

    final last = bytes.length - needle.length;
    for (var index = 0; index <= last; index++) {
      var matched = true;
      for (var offset = 0; offset < needle.length; offset++) {
        if (bytes[index + offset] != needle[offset]) {
          matched = false;
          break;
        }
      }
      if (matched) return true;
    }
    return false;
  }

  bool _isImage(Map<String, Object?> dictionary) {
    return dictionary['Subtype'] == const PdfName('Image');
  }

  PdfImageEntry _readImage(
    PdfLexer lexer,
    PdfObject object,
    Map<int, PdfObject> byNumber,
  ) {
    final dictionary = object.dictionary;

    final width = _intOf(dictionary['Width'], byNumber);
    final height = _intOf(dictionary['Height'], byNumber);
    final bits = _intOf(dictionary['BitsPerComponent'], byNumber);
    final filters = _filterNames(dictionary['Filter'], byNumber);
    final colorSpace = _colorSpaceName(dictionary['ColorSpace'], byNumber);
    final filterLabel = filters.join(' + ');

    PdfImageEntry skipped(PdfImageSkipReason reason) {
      return PdfImageEntry.skipped(
        objectNumber: object.number,
        width: width,
        height: height,
        reason: reason,
        filter: filterLabel,
        colorSpace: colorSpace,
      );
    }

    if (width <= 0 || height <= 0) return skipped(PdfImageSkipReason.malformed);
    if (width * height > AppConstants.pdfExtractMaxPixels) {
      return skipped(PdfImageSkipReason.tooLarge);
    }
    if (object.streamLength > AppConstants.pdfExtractMaxImageBytes) {
      return skipped(PdfImageSkipReason.tooLarge);
    }

    final raw = lexer.streamBytes(object);
    if (raw.isEmpty) return skipped(PdfImageSkipReason.malformed);

    // A JPEG inside a PDF is a whole JPEG file. Copying the bytes straight
    // out keeps the original quality: re-encoding would throw some away for
    // no reason at all.
    if (filters.isNotEmpty && filters.last == 'DCTDecode') {
      final jpeg = filters.length == 1
          ? raw
          : _undoLeadingFilters(filters, raw);
      if (jpeg == null) return skipped(PdfImageSkipReason.unsupportedFilter);

      return PdfImageEntry(
        objectNumber: object.number,
        width: width,
        height: height,
        filter: filterLabel,
        colorSpace: colorSpace,
        bytes: jpeg,
        format: PdfImageFormat.jpeg,
      );
    }

    final isRaw = filters.isEmpty;
    final isFlate = filters.length == 1 && filters.first == 'FlateDecode';
    if (!isRaw && !isFlate) {
      return skipped(PdfImageSkipReason.unsupportedFilter);
    }

    // A 1-bit mask or a 4-bit palette would need its own unpacking path, and
    // neither is worth the code until someone actually needs it.
    if (bits != 8) return skipped(PdfImageSkipReason.unsupportedBitDepth);

    final components = _componentsFor(colorSpace);
    if (components == 0)
      return skipped(PdfImageSkipReason.unsupportedColorSpace);

    final expected = width * height * components;
    if (expected > AppConstants.pdfExtractMaxImageBytes) {
      return skipped(PdfImageSkipReason.tooLarge);
    }

    Uint8List pixels;
    if (isRaw) {
      pixels = raw;
    } else {
      final inflated = _inflate(raw);
      if (inflated == null) return skipped(PdfImageSkipReason.decodeFailed);
      pixels = inflated;
    }

    if (pixels.length < expected) return skipped(PdfImageSkipReason.malformed);

    final png = _encodePng(
      width: width,
      height: height,
      components: components,
      pixels: pixels,
    );
    if (png == null) return skipped(PdfImageSkipReason.decodeFailed);

    return PdfImageEntry(
      objectNumber: object.number,
      width: width,
      height: height,
      filter: filterLabel.isEmpty ? 'none' : filterLabel,
      colorSpace: colorSpace,
      bytes: png,
      format: PdfImageFormat.png,
    );
  }

  /// Undoes everything before a trailing `DCTDecode`.
  ///
  /// `[FlateDecode, DCTDecode]` is rare but legal, and means a JPEG that was
  /// then zipped. Anything else in front of the JPEG is refused.
  Uint8List? _undoLeadingFilters(List<String> filters, Uint8List raw) {
    var current = raw;
    for (final filter in filters.sublist(0, filters.length - 1)) {
      if (filter != 'FlateDecode') return null;
      final inflated = _inflate(current);
      if (inflated == null) return null;
      current = inflated;
    }
    return current;
  }

  Uint8List? _inflate(Uint8List data) {
    try {
      final out = ZLibDecoder().convert(data);
      return out is Uint8List ? out : Uint8List.fromList(out);
    } catch (_) {
      // Some writers leave the zlib header off. Try again as a bare deflate
      // stream before giving up, because that file is otherwise fine.
      try {
        final out = ZLibDecoder(raw: true).convert(data);
        return out is Uint8List ? out : Uint8List.fromList(out);
      } catch (_) {
        return null;
      }
    }
  }

  Uint8List? _encodePng({
    required int width,
    required int height,
    required int components,
    required Uint8List pixels,
  }) {
    try {
      final image = img.Image(
        width: width,
        height: height,
        numChannels: components == 1 ? 1 : 3,
      );

      var source = 0;
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          if (components == 1) {
            final grey = pixels[source];
            image.setPixelRgb(x, y, grey, grey, grey);
            source += 1;
          } else {
            image.setPixelRgb(
              x,
              y,
              pixels[source],
              pixels[source + 1],
              pixels[source + 2],
            );
            source += 3;
          }
        }
      }

      return img.encodePng(image);
    } catch (_) {
      return null;
    }
  }

  /// How many bytes one pixel takes in the named colour space.
  ///
  /// Zero means the extractor will not touch it.
  int _componentsFor(String colorSpace) {
    switch (colorSpace) {
      case 'DeviceRGB':
      case 'CalRGB':
      case 'RGB':
        return 3;
      case 'DeviceGray':
      case 'CalGray':
      case 'G':
        return 1;
      default:
        return 0;
    }
  }

  /// The filter chain, always as a list even when the PDF wrote one name.
  List<String> _filterNames(Object? value, Map<int, PdfObject> byNumber) {
    final resolved = PdfLexer.resolve(value, byNumber);

    if (resolved is PdfName) return <String>[resolved.value];
    if (resolved is List) {
      return resolved
          .map((item) => PdfLexer.resolve(item, byNumber))
          .whereType<PdfName>()
          .map((name) => name.value)
          .toList(growable: false);
    }
    return const <String>[];
  }

  /// The colour space name, reaching through the forms that wrap one.
  String _colorSpaceName(Object? value, Map<int, PdfObject> byNumber) {
    final resolved = PdfLexer.resolve(value, byNumber);

    if (resolved is PdfName) return resolved.value;

    if (resolved is List && resolved.isNotEmpty) {
      final head = PdfLexer.resolve(resolved.first, byNumber);
      if (head is! PdfName) return '';

      // `[/ICCBased 8 0 R]` is the common wrapper. The stream it points at
      // says how many components it has, and that is enough to treat it as
      // plain grey or RGB.
      if (head.value == 'ICCBased' && resolved.length > 1) {
        final profile = PdfLexer.resolve(resolved[1], byNumber);
        if (profile is Map<String, Object?>) {
          final count = _intOf(profile['N'], byNumber);
          if (count == 1) return 'DeviceGray';
          if (count == 3) return 'DeviceRGB';
        }
        return 'ICCBased';
      }

      return head.value;
    }

    return '';
  }

  int _intOf(Object? value, Map<int, PdfObject> byNumber) {
    final resolved = PdfLexer.resolve(value, byNumber);
    if (resolved is int) return resolved;
    if (resolved is num) return resolved.toInt();
    return 0;
  }
}

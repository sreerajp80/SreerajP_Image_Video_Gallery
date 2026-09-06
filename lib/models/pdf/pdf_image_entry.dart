import 'dart:typed_data';

/// Why an image inside a PDF could not be pulled back out.
///
/// A reason, not a message. Every skipped image is still listed with its
/// reason, because "this PDF has nine pictures and you got seven" is a far
/// better thing to tell someone than quietly handing over seven.
enum PdfImageSkipReason {
  /// Compressed with something the extractor does not decode, such as
  /// `JPXDecode`, `JBIG2Decode` or `CCITTFaxDecode`.
  unsupportedFilter,

  /// A colour space the extractor does not turn into pixels, such as
  /// `Indexed`, `Separation` or `DeviceCMYK`.
  unsupportedColorSpace,

  /// Not eight bits per colour component.
  unsupportedBitDepth,

  /// Bigger than the caps allow.
  tooLarge,

  /// The object is there but does not hold the pixels it claims to.
  malformed,

  /// Decompression was attempted and failed.
  decodeFailed,
}

/// The picture format an extracted image is written in.
enum PdfImageFormat {
  /// Copied straight out; the PDF already held a JPEG.
  jpeg,

  /// Re-encoded from raw pixels.
  png;

  /// The file extension, without the dot.
  String get extension => this == PdfImageFormat.jpeg ? 'jpg' : 'png';

  /// The MIME type MediaStore is told about.
  String get mimeType =>
      this == PdfImageFormat.jpeg ? 'image/jpeg' : 'image/png';
}

/// One image found inside a PDF.
///
/// Carries the bytes when it could be extracted, and a reason when it could
/// not. [bytes] is null in the second case, and that is the only difference
/// the screen needs to look at.
class PdfImageEntry {
  /// The PDF object number it came from, used to build a stable file name.
  final int objectNumber;

  /// Pixel width as the PDF declares it.
  final int width;

  /// Pixel height as the PDF declares it.
  final int height;

  /// The filter chain named in the object, for the details line.
  final String filter;

  /// The colour space named in the object.
  final String colorSpace;

  /// The bytes ready to write, or null when this one was skipped.
  final Uint8List? bytes;

  /// The format [bytes] is in.
  final PdfImageFormat format;

  /// Why it was skipped, or null when it was extracted.
  final PdfImageSkipReason? skipReason;

  const PdfImageEntry({
    required this.objectNumber,
    required this.width,
    required this.height,
    this.filter = '',
    this.colorSpace = '',
    this.bytes,
    this.format = PdfImageFormat.png,
    this.skipReason,
  });

  /// A skipped image, listed so the count adds up.
  const PdfImageEntry.skipped({
    required this.objectNumber,
    required this.width,
    required this.height,
    required PdfImageSkipReason reason,
    this.filter = '',
    this.colorSpace = '',
  }) : bytes = null,
       format = PdfImageFormat.png,
       skipReason = reason;

  /// Whether this one can be saved.
  bool get isExtractable => bytes != null && bytes!.isNotEmpty;

  /// Size on disk once saved, in bytes. Zero for a skipped image.
  int get byteCount => bytes?.length ?? 0;

  /// The file name this image is saved under, before any clash is resolved.
  String get suggestedFileName => 'pdf_image_$objectNumber.${format.extension}';

  PdfImageEntry copyWith({
    int? objectNumber,
    int? width,
    int? height,
    String? filter,
    String? colorSpace,
    Uint8List? bytes,
    PdfImageFormat? format,
    PdfImageSkipReason? skipReason,
  }) {
    return PdfImageEntry(
      objectNumber: objectNumber ?? this.objectNumber,
      width: width ?? this.width,
      height: height ?? this.height,
      filter: filter ?? this.filter,
      colorSpace: colorSpace ?? this.colorSpace,
      bytes: bytes ?? this.bytes,
      format: format ?? this.format,
      skipReason: skipReason ?? this.skipReason,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PdfImageEntry &&
        other.objectNumber == objectNumber &&
        other.width == width &&
        other.height == height &&
        other.filter == filter &&
        other.colorSpace == colorSpace &&
        other.format == format &&
        other.skipReason == skipReason &&
        other.byteCount == byteCount;
  }

  @override
  int get hashCode => Object.hash(
    objectNumber,
    width,
    height,
    filter,
    colorSpace,
    format,
    skipReason,
    byteCount,
  );

  @override
  String toString() =>
      'PdfImageEntry($objectNumber, ${width}x$height, ${format.name})';
}

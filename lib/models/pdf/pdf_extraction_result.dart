import 'package:in_sreerajp_imgvidgal/models/pdf/pdf_image_entry.dart';

/// Why a whole PDF could not be read.
///
/// A reason, not a message. The screen turns it into localised text.
enum PdfRefusalReason {
  /// The file does not start with `%PDF-`.
  notAPdf,

  /// The file is password protected or otherwise encrypted.
  encrypted,

  /// Bigger than the extractor will open.
  fileTooLarge,

  /// The file is there but nothing could be read out of it.
  unreadable,
}

/// What one pass over a PDF found.
///
/// A refused file and an empty file are different things, and the screen says
/// something different for each, so the refusal is carried rather than being
/// flattened into "no images".
class PdfExtractionResult {
  /// Every image object found, extractable or not, in file order.
  final List<PdfImageEntry> entries;

  /// Why the whole file was refused, or null when it was read.
  final PdfRefusalReason? refusal;

  /// Whether the image count hit the cap and the rest were left unread.
  final bool wasTruncated;

  const PdfExtractionResult({
    this.entries = const <PdfImageEntry>[],
    this.refusal,
    this.wasTruncated = false,
  });

  /// A file that could not be opened at all.
  const PdfExtractionResult.refused(PdfRefusalReason reason)
    : entries = const <PdfImageEntry>[],
      refusal = reason,
      wasTruncated = false;

  /// Whether the file was refused outright.
  bool get isRefused => refusal != null;

  /// The images that can actually be saved.
  List<PdfImageEntry> get extractable =>
      entries.where((entry) => entry.isExtractable).toList(growable: false);

  /// The images that were found but cannot be saved.
  List<PdfImageEntry> get skipped =>
      entries.where((entry) => !entry.isExtractable).toList(growable: false);

  /// Whether there is nothing at all to show.
  bool get isEmpty => entries.isEmpty;

  @override
  String toString() =>
      'PdfExtractionResult(${entries.length} found, '
      '${extractable.length} extractable, refusal: ${refusal?.name})';
}

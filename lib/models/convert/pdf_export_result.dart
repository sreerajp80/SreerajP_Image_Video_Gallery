import 'package:flutter/foundation.dart';

/// What an export produced.
@immutable
class PdfExportResult {
  /// Full path of the new PDF.
  final String path;

  /// Size of the PDF in bytes.
  final int bytes;

  /// How many photos made it into the document.
  final int pageCount;

  /// How many chosen photos could not be read and were left out.
  final int skippedCount;

  const PdfExportResult({
    required this.path,
    required this.bytes,
    required this.pageCount,
    required this.skippedCount,
  });

  @override
  String toString() =>
      'PdfExportResult($pageCount pages, $bytes bytes, $skippedCount skipped)';
}

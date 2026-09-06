import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/convert/conversion_request.dart';
import 'package:in_sreerajp_imgvidgal/models/convert/image_output_format.dart';
import 'package:in_sreerajp_imgvidgal/models/convert/pdf_export_options.dart';
import 'package:in_sreerajp_imgvidgal/models/convert/resize_spec.dart';
import 'package:in_sreerajp_imgvidgal/services/convert/format_conversion_service.dart';
import 'package:in_sreerajp_imgvidgal/services/convert/output_naming_service.dart';
import 'package:in_sreerajp_imgvidgal/services/convert/pdf_layout_service.dart';
import 'package:pdf/pdf.dart';

/// Thrown when no PDF could be produced at all.
class PdfExportException implements Exception {
  final String message;

  const PdfExportException(this.message);

  @override
  String toString() => 'PdfExportException: $message';
}

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

/// Builds a PDF document from a list of photos.
///
/// Each photo is shrunk and re-encoded as a JPEG first, on a background
/// isolate, so a twenty-photo document does not come out at hundreds of
/// megabytes. The JPEG is then embedded as it is, without a second decode.
///
/// A photo that cannot be read is skipped rather than failing the whole
/// export, because one damaged file in a long selection should not cost the
/// user the other nineteen pages.
class PdfExportService {
  final FormatConversionService _conversionService;
  final PdfLayoutService _layoutService;
  final OutputNamingService _namingService;

  PdfExportService({
    FormatConversionService? conversionService,
    PdfLayoutService layoutService = const PdfLayoutService(),
    OutputNamingService namingService = const OutputNamingService(),
  }) : _conversionService = conversionService ?? FormatConversionService(),
       _layoutService = layoutService,
       _namingService = namingService;

  /// Exports [imagePaths] as one PDF beside the first of them.
  ///
  /// [onProgress] is called after each photo is prepared, so the screen can
  /// show how far along the export is.
  Future<PdfExportResult> export({
    required List<String> imagePaths,
    required PdfExportOptions options,
    void Function(int done, int total)? onProgress,
  }) async {
    if (imagePaths.isEmpty) {
      throw const PdfExportException('No photos were chosen');
    }

    final chosen = imagePaths
        .take(_layoutService.pageCount(imagePaths.length))
        .toList(growable: false);

    final prepared = <_PreparedPage>[];
    var skipped = 0;

    for (var index = 0; index < chosen.length; index++) {
      final page = await _preparePage(chosen[index], options);
      if (page == null) {
        skipped++;
      } else {
        prepared.add(page);
      }
      onProgress?.call(index + 1, chosen.length);
    }

    if (prepared.isEmpty) {
      throw const PdfExportException('None of the chosen photos could be read');
    }

    final bytes = await _buildDocument(prepared, options);
    final file = await _namingService.saveBytes(
      sourcePath: chosen.first,
      suffix: AppConstants.pdfOutputSuffix,
      extension: 'pdf',
      bytes: bytes,
    );

    return PdfExportResult(
      path: file.path,
      bytes: bytes.length,
      pageCount: prepared.length,
      skippedCount: skipped,
    );
  }

  /// Reads one photo and turns it into a page-ready JPEG.
  ///
  /// Returns null when the file is missing, too big, or unreadable. Every
  /// failure here is expected rather than exceptional, so it is swallowed
  /// and reported as a skip.
  Future<_PreparedPage?> _preparePage(
    String path,
    PdfExportOptions options,
  ) async {
    try {
      final file = File(path);
      if (!await file.exists()) return null;

      final length = await file.length();
      if (!_namingService.isConvertibleSize(length)) return null;

      final sourceBytes = await file.readAsBytes();
      final encoded = await _conversionService.convert(
        sourceBytes: sourceBytes,
        request: ConversionRequest(
          format: ImageOutputFormat.jpeg,
          quality: options.effectiveQuality,
          resize: const ResizeSpec(
            mode: ResizeMode.longestSide,
            longestSide: AppConstants.pdfImageMaxSide,
          ),
        ),
      );

      return _PreparedPage(
        jpegBytes: encoded.bytes,
        width: encoded.width,
        height: encoded.height,
      );
    } catch (_) {
      // One bad photo must not cost the user the rest of the document.
      return null;
    }
  }

  /// Lays the prepared photos out and writes the document bytes.
  Future<Uint8List> _buildDocument(
    List<_PreparedPage> pages,
    PdfExportOptions options,
  ) async {
    try {
      final document = PdfDocument();

      for (final page in pages) {
        final size = _layoutService.pageSize(
          options: options,
          imageWidth: page.width,
          imageHeight: page.height,
        );
        final placement = _layoutService.placement(
          options: options,
          page: size,
          imageWidth: page.width,
          imageHeight: page.height,
        );

        final image = PdfImage.jpeg(document, image: page.jpegBytes);
        final pdfPage = PdfPage(
          document,
          pageFormat: PdfPageFormat(size.width, size.height),
        );

        // PDF measures upwards from the bottom left, while the layout
        // service works downwards from the top left, so the top edge is
        // flipped here and nowhere else.
        final bottom = size.height - placement.top - placement.height;
        pdfPage.getGraphics().drawImage(
          image,
          placement.left,
          bottom,
          placement.width,
          placement.height,
        );
      }

      return await document.save();
    } catch (error) {
      throw PdfExportException('The PDF could not be created: $error');
    }
  }
}

/// One photo, ready to be placed on a page.
@immutable
class _PreparedPage {
  final Uint8List jpegBytes;
  final int width;
  final int height;

  const _PreparedPage({
    required this.jpegBytes,
    required this.width,
    required this.height,
  });
}

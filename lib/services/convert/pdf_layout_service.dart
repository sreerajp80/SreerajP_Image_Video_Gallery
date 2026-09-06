import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/convert/pdf_export_options.dart';

/// A size in PDF points (1/72 inch).
@immutable
class PagePoints {
  final double width;
  final double height;

  const PagePoints(this.width, this.height);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PagePoints &&
          runtimeType == other.runtimeType &&
          width == other.width &&
          height == other.height;

  @override
  int get hashCode => Object.hash(width, height);

  @override
  String toString() =>
      'PagePoints(${width.toStringAsFixed(2)} x ${height.toStringAsFixed(2)})';
}

/// Where a picture sits on its page, in PDF points from the top left.
@immutable
class PagePlacement {
  final double left;
  final double top;
  final double width;
  final double height;

  const PagePlacement({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PagePlacement &&
          runtimeType == other.runtimeType &&
          left == other.left &&
          top == other.top &&
          width == other.width &&
          height == other.height;

  @override
  int get hashCode => Object.hash(left, top, width, height);

  @override
  String toString() => 'PagePlacement($left, $top, ${width}x$height)';
}

/// Page maths for the PDF export.
///
/// Pure on purpose: it never opens a file and never touches the `pdf`
/// package, so every page size, rotation, and fit rule can be checked in a
/// plain unit test.
class PdfLayoutService {
  const PdfLayoutService();

  /// The page size for a photo of [imageWidth] by [imageHeight].
  ///
  /// A fit-to-image page is made exactly as large as the photo, so nothing
  /// is cropped and there is no blank border. A fixed page is turned to
  /// match the photo when the orientation is set to automatic.
  PagePoints pageSize({
    required PdfExportOptions options,
    required int imageWidth,
    required int imageHeight,
  }) {
    final width = math.max(1, imageWidth).toDouble();
    final height = math.max(1, imageHeight).toDouble();

    if (options.pageSize == PdfPageSize.fitImage) {
      return PagePoints(width, height);
    }

    final base = _basePage(options.pageSize);
    switch (options.orientation) {
      case PdfOrientation.portrait:
        return base;
      case PdfOrientation.landscape:
        return PagePoints(base.height, base.width);
      case PdfOrientation.auto:
        // A wide photo gets a wide page, so a landscape shot is not shrunk
        // into a narrow column with big white bands above and below it.
        return width > height ? PagePoints(base.height, base.width) : base;
    }
  }

  /// Where a photo of [imageWidth] by [imageHeight] is drawn on [page].
  ///
  /// `contain` fits the whole photo inside the margins. `fill` covers the
  /// area completely and lets the overhanging edges be cut off.
  PagePlacement placement({
    required PdfExportOptions options,
    required PagePoints page,
    required int imageWidth,
    required int imageHeight,
  }) {
    final margin = options.effectiveMargin;
    final safeMargin = _fitMargin(margin, page);

    final areaWidth = math.max(1.0, page.width - safeMargin * 2);
    final areaHeight = math.max(1.0, page.height - safeMargin * 2);

    final width = math.max(1, imageWidth).toDouble();
    final height = math.max(1, imageHeight).toDouble();

    final scaleToFit = math.min(areaWidth / width, areaHeight / height);
    final scaleToFill = math.max(areaWidth / width, areaHeight / height);
    final scale = options.fitMode == PdfFitMode.fill ? scaleToFill : scaleToFit;

    final drawWidth = width * scale;
    final drawHeight = height * scale;

    return PagePlacement(
      left: safeMargin + (areaWidth - drawWidth) / 2,
      top: safeMargin + (areaHeight - drawHeight) / 2,
      width: drawWidth,
      height: drawHeight,
    );
  }

  /// How many photos will actually make it into the document.
  ///
  /// A very long selection is cut at the page cap rather than refused, so
  /// the user still gets a document.
  int pageCount(int selectedCount) =>
      selectedCount.clamp(0, AppConstants.pdfMaxPages);

  PagePoints _basePage(PdfPageSize size) {
    switch (size) {
      case PdfPageSize.a4:
        return const PagePoints(
          AppConstants.pdfA4WidthPoints,
          AppConstants.pdfA4HeightPoints,
        );
      case PdfPageSize.letter:
        return const PagePoints(
          AppConstants.pdfLetterWidthPoints,
          AppConstants.pdfLetterHeightPoints,
        );
      case PdfPageSize.fitImage:
        // Handled before this is ever called; kept so the switch is total.
        return const PagePoints(
          AppConstants.pdfA4WidthPoints,
          AppConstants.pdfA4HeightPoints,
        );
    }
  }

  /// Shrinks a margin that would leave no room for the photo at all.
  double _fitMargin(double margin, PagePoints page) {
    final smallestSide = math.min(page.width, page.height);
    final largestUsable = math.max(0.0, smallestSide / 2 - 1);
    return margin.clamp(0.0, largestUsable);
  }
}

import 'package:flutter/foundation.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';

/// The paper size each page uses.
enum PdfPageSize {
  /// 210 x 297 mm.
  a4,

  /// 8.5 x 11 inches.
  letter,

  /// The page is made exactly the size of the photo on it, so nothing is
  /// cropped and no blank border appears.
  fitImage;

  static PdfPageSize fromName(String value) {
    return PdfPageSize.values.firstWhere(
      (size) => size.name == value,
      orElse: () => PdfPageSize.a4,
    );
  }
}

/// Which way round a fixed-size page is turned.
enum PdfOrientation {
  portrait,
  landscape,

  /// Each page follows the shape of its own photo.
  auto;

  static PdfOrientation fromName(String value) {
    return PdfOrientation.values.firstWhere(
      (value1) => value1.name == value,
      orElse: () => PdfOrientation.auto,
    );
  }
}

/// How a photo is placed inside its page.
enum PdfFitMode {
  /// Fit the whole photo on the page. Nothing is cut off.
  contain,

  /// Fill the page. The photo's edges are cut off if the shapes differ.
  fill;

  static PdfFitMode fromName(String value) {
    return PdfFitMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => PdfFitMode.contain,
    );
  }
}

/// Everything the PDF export screen lets the user choose.
@immutable
class PdfExportOptions {
  final PdfPageSize pageSize;
  final PdfOrientation orientation;
  final PdfFitMode fitMode;

  /// Blank border around the photo, in PDF points (1/72 inch).
  final double marginPoints;

  /// JPEG quality of the photos placed in the document, 10 to 100.
  final int imageQuality;

  const PdfExportOptions({
    this.pageSize = PdfPageSize.a4,
    this.orientation = PdfOrientation.auto,
    this.fitMode = PdfFitMode.contain,
    this.marginPoints = AppConstants.pdfDefaultMarginPoints,
    this.imageQuality = AppConstants.pdfImageQuality,
  });

  /// The quality actually used, pulled into the allowed range.
  int get effectiveQuality => imageQuality.clamp(
    AppConstants.convertMinQuality,
    AppConstants.convertMaxQuality,
  );

  /// The margin actually used. A fit-to-image page never has one, because a
  /// border would defeat the point of matching the photo exactly.
  double get effectiveMargin {
    if (pageSize == PdfPageSize.fitImage) return 0;
    return marginPoints.clamp(0.0, AppConstants.pdfLargeMarginPoints);
  }

  PdfExportOptions copyWith({
    PdfPageSize? pageSize,
    PdfOrientation? orientation,
    PdfFitMode? fitMode,
    double? marginPoints,
    int? imageQuality,
  }) {
    return PdfExportOptions(
      pageSize: pageSize ?? this.pageSize,
      orientation: orientation ?? this.orientation,
      fitMode: fitMode ?? this.fitMode,
      marginPoints: marginPoints ?? this.marginPoints,
      imageQuality: imageQuality ?? this.imageQuality,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'pageSize': pageSize.name,
    'orientation': orientation.name,
    'fitMode': fitMode.name,
    'marginPoints': marginPoints,
    'imageQuality': imageQuality,
  };

  factory PdfExportOptions.fromMap(Map<String, dynamic> map) {
    return PdfExportOptions(
      pageSize: PdfPageSize.fromName(map['pageSize'] as String? ?? ''),
      orientation: PdfOrientation.fromName(map['orientation'] as String? ?? ''),
      fitMode: PdfFitMode.fromName(map['fitMode'] as String? ?? ''),
      marginPoints:
          (map['marginPoints'] as num?)?.toDouble() ??
          AppConstants.pdfDefaultMarginPoints,
      imageQuality:
          (map['imageQuality'] as num?)?.toInt() ??
          AppConstants.pdfImageQuality,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfExportOptions &&
          runtimeType == other.runtimeType &&
          pageSize == other.pageSize &&
          orientation == other.orientation &&
          fitMode == other.fitMode &&
          marginPoints == other.marginPoints &&
          imageQuality == other.imageQuality;

  @override
  int get hashCode =>
      Object.hash(pageSize, orientation, fitMode, marginPoints, imageQuality);

  @override
  String toString() =>
      'PdfExportOptions(${pageSize.name}, ${orientation.name}, '
      '${fitMode.name}, margin: $marginPoints)';
}

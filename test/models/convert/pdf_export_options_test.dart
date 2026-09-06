import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/convert/pdf_export_options.dart';

void main() {
  group('effectiveMargin', () {
    test('a fit-to-photo page never has a border', () {
      const options = PdfExportOptions(
        pageSize: PdfPageSize.fitImage,
        marginPoints: AppConstants.pdfLargeMarginPoints,
      );

      expect(options.effectiveMargin, 0);
    });

    test('a fixed page keeps the chosen border', () {
      const options = PdfExportOptions(
        pageSize: PdfPageSize.a4,
        marginPoints: AppConstants.pdfMediumMarginPoints,
      );

      expect(options.effectiveMargin, AppConstants.pdfMediumMarginPoints);
    });

    test('an over-large border is pulled back to the largest offered', () {
      const options = PdfExportOptions(
        pageSize: PdfPageSize.a4,
        marginPoints: 5000,
      );

      expect(options.effectiveMargin, AppConstants.pdfLargeMarginPoints);
    });

    test('a negative border is pulled up to none', () {
      const options = PdfExportOptions(
        pageSize: PdfPageSize.a4,
        marginPoints: -20,
      );

      expect(options.effectiveMargin, 0);
    });
  });

  group('effectiveQuality', () {
    test('the quality is kept inside the allowed range', () {
      expect(
        const PdfExportOptions(imageQuality: 1).effectiveQuality,
        AppConstants.convertMinQuality,
      );
      expect(
        const PdfExportOptions(imageQuality: 300).effectiveQuality,
        AppConstants.convertMaxQuality,
      );
      expect(const PdfExportOptions(imageQuality: 70).effectiveQuality, 70);
    });
  });

  group('serialisation', () {
    test('options survive a round trip through a map', () {
      const original = PdfExportOptions(
        pageSize: PdfPageSize.letter,
        orientation: PdfOrientation.landscape,
        fitMode: PdfFitMode.fill,
        marginPoints: AppConstants.pdfLargeMarginPoints,
        imageQuality: 70,
      );

      expect(PdfExportOptions.fromMap(original.toMap()), original);
    });

    test('unknown names fall back to the defaults', () {
      final options = PdfExportOptions.fromMap(<String, dynamic>{
        'pageSize': 'a3',
        'orientation': 'diagonal',
        'fitMode': 'squash',
      });

      expect(options.pageSize, PdfPageSize.a4);
      expect(options.orientation, PdfOrientation.auto);
      expect(options.fitMode, PdfFitMode.contain);
    });
  });
}

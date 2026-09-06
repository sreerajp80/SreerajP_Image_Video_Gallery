import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/convert/pdf_export_options.dart';
import 'package:in_sreerajp_imgvidgal/services/convert/pdf_layout_service.dart';

void main() {
  const service = PdfLayoutService();

  group('pageSize', () {
    test('a fit-to-photo page is exactly the size of the photo', () {
      final size = service.pageSize(
        options: const PdfExportOptions(pageSize: PdfPageSize.fitImage),
        imageWidth: 1234,
        imageHeight: 567,
      );

      expect(size, const PagePoints(1234, 567));
    });

    test('an upright page keeps A4 as it is', () {
      final size = service.pageSize(
        options: const PdfExportOptions(orientation: PdfOrientation.portrait),
        imageWidth: 2000,
        imageHeight: 1000,
      );

      expect(size.width, AppConstants.pdfA4WidthPoints);
      expect(size.height, AppConstants.pdfA4HeightPoints);
    });

    test('a sideways page turns A4 round', () {
      final size = service.pageSize(
        options: const PdfExportOptions(orientation: PdfOrientation.landscape),
        imageWidth: 1000,
        imageHeight: 2000,
      );

      expect(size.width, AppConstants.pdfA4HeightPoints);
      expect(size.height, AppConstants.pdfA4WidthPoints);
    });

    test('an automatic page follows the shape of the photo', () {
      final wide = service.pageSize(
        options: const PdfExportOptions(),
        imageWidth: 2000,
        imageHeight: 1000,
      );
      final tall = service.pageSize(
        options: const PdfExportOptions(),
        imageWidth: 1000,
        imageHeight: 2000,
      );

      expect(wide.width, greaterThan(wide.height));
      expect(tall.height, greaterThan(tall.width));
    });

    test('Letter is used when it is chosen', () {
      final size = service.pageSize(
        options: const PdfExportOptions(
          pageSize: PdfPageSize.letter,
          orientation: PdfOrientation.portrait,
        ),
        imageWidth: 100,
        imageHeight: 100,
      );

      expect(size.width, AppConstants.pdfLetterWidthPoints);
      expect(size.height, AppConstants.pdfLetterHeightPoints);
    });
  });

  group('placement with contain', () {
    test('the whole photo fits inside the page and is centred', () {
      const page = PagePoints(1000, 1000);
      final placement = service.placement(
        options: const PdfExportOptions(marginPoints: 0),
        page: page,
        imageWidth: 2000,
        imageHeight: 1000,
      );

      expect(placement.width, 1000);
      expect(placement.height, 500);
      expect(placement.left, 0);
      expect(placement.top, 250);
    });

    test('the border is left blank on every side', () {
      const page = PagePoints(1000, 1000);
      final placement = service.placement(
        options: const PdfExportOptions(marginPoints: 50),
        page: page,
        imageWidth: 1000,
        imageHeight: 1000,
      );

      expect(placement.left, 50);
      expect(placement.top, 50);
      expect(placement.width, 900);
      expect(placement.height, 900);
    });
  });

  group('placement with fill', () {
    test('the page is covered and the overhang is centred', () {
      const page = PagePoints(1000, 1000);
      final placement = service.placement(
        options: const PdfExportOptions(
          fitMode: PdfFitMode.fill,
          marginPoints: 0,
        ),
        page: page,
        imageWidth: 2000,
        imageHeight: 1000,
      );

      expect(placement.height, 1000);
      expect(placement.width, 2000);
      // Half of the extra width hangs off each side.
      expect(placement.left, -500);
    });
  });

  group('protective clamping', () {
    test('a border larger than the page still leaves room for the photo', () {
      const page = PagePoints(100, 100);
      final placement = service.placement(
        options: const PdfExportOptions(marginPoints: 500),
        page: page,
        imageWidth: 100,
        imageHeight: 100,
      );

      expect(placement.width, greaterThan(0));
      expect(placement.height, greaterThan(0));
    });

    test('a photo with no size does not break the maths', () {
      const page = PagePoints(100, 100);
      final placement = service.placement(
        options: const PdfExportOptions(marginPoints: 0),
        page: page,
        imageWidth: 0,
        imageHeight: 0,
      );

      expect(placement.width, greaterThan(0));
      expect(placement.height, greaterThan(0));
    });
  });

  group('pageCount', () {
    test('a normal selection is used as it is', () {
      expect(service.pageCount(12), 12);
    });

    test('a very long selection is cut at the cap', () {
      expect(
        service.pageCount(AppConstants.pdfMaxPages + 50),
        AppConstants.pdfMaxPages,
      );
    });

    test('an empty selection stays empty', () {
      expect(service.pageCount(0), 0);
    });
  });
}

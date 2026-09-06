import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/convert/conversion_request.dart';
import 'package:in_sreerajp_imgvidgal/models/convert/image_output_format.dart';
import 'package:in_sreerajp_imgvidgal/models/convert/resize_spec.dart';
import 'package:in_sreerajp_imgvidgal/models/convert/size_estimate.dart';

void main() {
  group('effectiveQuality', () {
    test('a quality inside the range is used as it is', () {
      const request = ConversionRequest(quality: 70);
      expect(request.effectiveQuality, 70);
    });

    test('a quality below the floor is pulled up', () {
      const request = ConversionRequest(quality: 1);
      expect(request.effectiveQuality, AppConstants.convertMinQuality);
    });

    test('a quality above the ceiling is pulled down', () {
      const request = ConversionRequest(quality: 500);
      expect(request.effectiveQuality, AppConstants.convertMaxQuality);
    });
  });

  group('serialisation', () {
    test('a request survives a round trip through JSON', () {
      const original = ConversionRequest(
        format: ImageOutputFormat.webp,
        quality: 62,
        resize: ResizeSpec(mode: ResizeMode.percent, percent: 45),
        stripMetadata: false,
      );

      expect(ConversionRequest.fromJson(original.toJson()), original);
    });

    test('an empty map gives a usable default request', () {
      final request = ConversionRequest.fromMap(<String, dynamic>{});

      expect(request.format, ImageOutputFormat.jpeg);
      expect(request.quality, AppConstants.convertDefaultQuality);
      expect(request.resize, ResizeSpec.original);
      expect(request.stripMetadata, isTrue);
    });
  });

  group('SizeEstimate', () {
    test('the saving is the difference against the original', () {
      const estimate = SizeEstimate(
        bytes: 400,
        width: 10,
        height: 10,
        originalBytes: 1000,
      );

      expect(estimate.savedBytes, 600);
      expect(estimate.savedFraction, closeTo(0.6, 0.0001));
      expect(estimate.isLarger, isFalse);
    });

    test('a copy that grew reports no saving rather than a negative one', () {
      const estimate = SizeEstimate(
        bytes: 2000,
        width: 10,
        height: 10,
        originalBytes: 1000,
      );

      expect(estimate.savedFraction, 0);
      expect(estimate.isLarger, isTrue);
    });

    test('an unknown original size reports no saving', () {
      const estimate = SizeEstimate(
        bytes: 500,
        width: 10,
        height: 10,
        originalBytes: 0,
      );

      expect(estimate.savedFraction, 0);
      expect(estimate.isLarger, isFalse);
    });
  });
}

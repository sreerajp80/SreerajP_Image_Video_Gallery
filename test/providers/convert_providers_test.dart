import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/convert/image_output_format.dart';
import 'package:in_sreerajp_imgvidgal/models/convert/resize_spec.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/providers/convert_providers.dart';

void main() {
  group('ConversionRequestNotifier', () {
    late ConversionRequestNotifier notifier;

    setUp(() {
      notifier = ConversionRequestNotifier(
        initialFormat: ImageOutputFormat.jpeg,
      );
    });

    tearDown(() => notifier.dispose());

    test('starts on the given format', () {
      expect(notifier.state.format, ImageOutputFormat.jpeg);

      notifier.setFormat(ImageOutputFormat.webp);
      expect(notifier.state.format, ImageOutputFormat.webp);
    });

    test('quality is kept inside its limits', () {
      notifier.setQuality(0);
      expect(notifier.state.quality, AppConstants.convertMinQuality);

      notifier.setQuality(1000);
      expect(notifier.state.quality, AppConstants.convertMaxQuality);
    });

    test('sizes are kept inside their limits', () {
      notifier.setLongestSide(1);
      expect(
        notifier.state.resize.longestSide,
        AppConstants.convertMinLongestSide,
      );

      notifier.setPercent(9999);
      expect(notifier.state.resize.percent, AppConstants.convertMaxPercent);

      notifier.setExactSize(width: 0, height: 999999);
      expect(notifier.state.resize.width, 1);
      expect(notifier.state.resize.height, AppConstants.convertMaxLongestSide);
    });

    test('mode, aspect and metadata switches are stored', () {
      notifier
        ..setResizeMode(ResizeMode.values.last)
        ..setKeepAspect(false)
        ..setStripMetadata(true);

      expect(notifier.state.resize.mode, ResizeMode.values.last);
      expect(notifier.state.resize.keepAspect, isFalse);
      expect(notifier.state.stripMetadata, isTrue);
    });
  });

  test('a photo opens on its own format', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final item = MediaItem(
      id: 'c1',
      path: '/storage/DCIM/Camera/C1.png',
      displayName: 'C1.png',
      mediaType: MediaType.image,
      mimeType: 'image/png',
      size: 1000,
      dateAdded: DateTime(2026, 9),
      dateModified: DateTime(2026, 9),
    );
    container.listen(conversionRequestProvider(item), (_, _) {});

    expect(
      container.read(conversionRequestProvider(item)).format,
      ImageOutputFormat.png,
    );
  });

  group('PdfSelectionNotifier', () {
    late PdfSelectionNotifier notifier;

    setUp(() => notifier = PdfSelectionNotifier());
    tearDown(() => notifier.dispose());

    test('keeps the order photos were picked in', () {
      notifier
        ..toggle('b')
        ..toggle('a')
        ..toggle('c');

      expect(notifier.state, <String>['b', 'a', 'c']);
    });

    test('a second tap removes a photo', () {
      notifier
        ..toggle('a')
        ..toggle('b')
        ..toggle('a');

      expect(notifier.state, <String>['b']);
      expect(notifier.contains('a'), isFalse);
    });

    test('stops at the page limit', () {
      for (var i = 0; i < AppConstants.pdfMaxPages + 5; i++) {
        notifier.toggle('p$i');
      }

      expect(notifier.state.length, AppConstants.pdfMaxPages);
      notifier.clear();
      expect(notifier.state, isEmpty);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/convert/image_output_format.dart';

void main() {
  group('extension and MIME type', () {
    test('every format has a matching extension and MIME type', () {
      expect(ImageOutputFormat.jpeg.extension, 'jpg');
      expect(ImageOutputFormat.png.extension, 'png');
      expect(ImageOutputFormat.webp.extension, 'webp');
      expect(ImageOutputFormat.bmp.extension, 'bmp');

      expect(ImageOutputFormat.jpeg.mimeType, 'image/jpeg');
      expect(ImageOutputFormat.png.mimeType, 'image/png');
      expect(ImageOutputFormat.webp.mimeType, 'image/webp');
      expect(ImageOutputFormat.bmp.mimeType, 'image/bmp');
    });
  });

  group('capabilities', () {
    test('only the lossy formats take a quality value', () {
      expect(ImageOutputFormat.jpeg.supportsQuality, isTrue);
      expect(ImageOutputFormat.webp.supportsQuality, isTrue);
      expect(ImageOutputFormat.png.supportsQuality, isFalse);
      expect(ImageOutputFormat.bmp.supportsQuality, isFalse);
    });

    test('only PNG and WEBP keep see-through pixels', () {
      expect(ImageOutputFormat.png.supportsTransparency, isTrue);
      expect(ImageOutputFormat.webp.supportsTransparency, isTrue);
      expect(ImageOutputFormat.jpeg.supportsTransparency, isFalse);
      expect(ImageOutputFormat.bmp.supportsTransparency, isFalse);
    });

    test('only WEBP needs the platform encoder', () {
      expect(ImageOutputFormat.webp.needsPlatformEncoder, isTrue);
      for (final format in ImageOutputFormat.values) {
        if (format == ImageOutputFormat.webp) continue;
        expect(format.needsPlatformEncoder, isFalse);
      }
    });
  });

  group('fromName', () {
    test('a known name round trips', () {
      for (final format in ImageOutputFormat.values) {
        expect(ImageOutputFormat.fromName(format.name), format);
      }
    });

    test('an unknown name falls back to JPEG', () {
      expect(ImageOutputFormat.fromName('tiff'), ImageOutputFormat.jpeg);
      expect(ImageOutputFormat.fromName(''), ImageOutputFormat.jpeg);
    });
  });

  group('forFileName', () {
    test('the format matches the extension, whatever the case', () {
      expect(ImageOutputFormat.forFileName('a.PNG'), ImageOutputFormat.png);
      expect(ImageOutputFormat.forFileName('a.webp'), ImageOutputFormat.webp);
      expect(ImageOutputFormat.forFileName('a.BMP'), ImageOutputFormat.bmp);
      expect(ImageOutputFormat.forFileName('a.jpeg'), ImageOutputFormat.jpeg);
    });

    test('anything unrecognised is treated as JPEG', () {
      expect(ImageOutputFormat.forFileName('a.heic'), ImageOutputFormat.jpeg);
      expect(
        ImageOutputFormat.forFileName('no-extension'),
        ImageOutputFormat.jpeg,
      );
    });
  });
}

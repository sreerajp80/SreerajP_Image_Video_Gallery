import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/services/media/media_type_resolver.dart';

void main() {
  group('MediaTypeResolver', () {
    test('resolves common image and video MIME types', () {
      expect(
        MediaTypeResolver.resolve(mimeType: 'image/jpeg', fileName: 'a.jpg'),
        MediaType.image,
      );
      expect(
        MediaTypeResolver.resolve(mimeType: 'image/png', fileName: 'a.png'),
        MediaType.image,
      );
      expect(
        MediaTypeResolver.resolve(mimeType: 'video/mp4', fileName: 'a.mp4'),
        MediaType.video,
      );
    });

    test('detects GIF and SVG from either MIME type or extension', () {
      expect(
        MediaTypeResolver.resolve(mimeType: 'image/gif', fileName: 'a.gif'),
        MediaType.gif,
      );
      expect(
        MediaTypeResolver.resolve(mimeType: '', fileName: 'anim.GIF'),
        MediaType.gif,
      );
      expect(
        MediaTypeResolver.resolve(mimeType: 'image/svg+xml', fileName: 'a.svg'),
        MediaType.svg,
      );
      expect(
        MediaTypeResolver.resolve(mimeType: null, fileName: 'logo.svg'),
        MediaType.svg,
      );
    });

    test('detects every supported RAW extension', () {
      for (final extension in MediaTypeResolver.rawExtensions) {
        expect(
          MediaTypeResolver.resolve(fileName: 'shot.$extension'),
          MediaType.rawImage,
          reason: '.$extension should be RAW',
        );
      }
    });

    test('detects RAW from a vendor MIME type even without an extension', () {
      expect(
        MediaTypeResolver.resolve(
          mimeType: 'image/x-adobe-dng',
          fileName: 'no_extension',
        ),
        MediaType.rawImage,
      );
    });

    test('detects video from extension when the MIME type is missing', () {
      expect(
        MediaTypeResolver.resolve(mimeType: '', fileName: 'clip.mkv'),
        MediaType.video,
      );
      expect(MediaTypeResolver.resolve(fileName: 'clip.MOV'), MediaType.video);
    });

    test('falls back to image for unknown, empty, and null input', () {
      expect(MediaTypeResolver.resolve(), MediaType.image);
      expect(
        MediaTypeResolver.resolve(mimeType: '', fileName: ''),
        MediaType.image,
      );
      expect(
        MediaTypeResolver.resolve(
          mimeType: 'application/octet-stream',
          fileName: 'mystery.xyz',
        ),
        MediaType.image,
      );
    });

    test('extensionOf handles dotless names and trailing dots', () {
      expect(MediaTypeResolver.extensionOf('photo.jpeg'), 'jpeg');
      expect(MediaTypeResolver.extensionOf('archive.tar.gz'), 'gz');
      expect(MediaTypeResolver.extensionOf('nodot'), '');
      expect(MediaTypeResolver.extensionOf('trailing.'), '');
      expect(MediaTypeResolver.extensionOf(null), '');
    });
  });
}

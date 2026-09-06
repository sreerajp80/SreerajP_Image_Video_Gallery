import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/widgets/media/media_badges.dart';

MediaItem sized({int? width, int? height, int? durationMs}) {
  final date = DateTime(2026, 8, 29);
  return MediaItem(
    id: 'x',
    path: '/storage/emulated/0/DCIM/x.jpg',
    displayName: 'x.jpg',
    mediaType: MediaType.image,
    mimeType: 'image/jpeg',
    size: 100,
    dateAdded: date,
    dateModified: date,
    width: width,
    height: height,
    durationMs: durationMs,
  );
}

void main() {
  group('formatMediaDuration', () {
    test('formats under a minute', () {
      expect(formatMediaDuration(9000), '0:09');
      expect(formatMediaDuration(59000), '0:59');
    });

    test('formats minutes and seconds', () {
      expect(formatMediaDuration(60000), '1:00');
      expect(formatMediaDuration(95000), '1:35');
      expect(formatMediaDuration(599000), '9:59');
    });

    test('adds an hours field past one hour', () {
      expect(formatMediaDuration(3600000), '1:00:00');
      expect(formatMediaDuration(3725000), '1:02:05');
    });

    test('returns null for a missing or broken duration', () {
      expect(formatMediaDuration(null), isNull);
      expect(formatMediaDuration(0), isNull);
      expect(formatMediaDuration(-500), isNull);
    });
  });

  group('isHighResolution', () {
    test('is true when the shorter edge reaches the threshold', () {
      expect(isHighResolution(sized(width: 1920, height: 1080)), isTrue);
      expect(isHighResolution(sized(width: 1080, height: 1920)), isTrue);
      expect(isHighResolution(sized(width: 4000, height: 3000)), isTrue);
    });

    test('is false below the threshold', () {
      expect(isHighResolution(sized(width: 1920, height: 1079)), isFalse);
      expect(isHighResolution(sized(width: 640, height: 480)), isFalse);
    });

    test('is false when the size is unknown or invalid', () {
      expect(isHighResolution(sized()), isFalse);
      expect(isHighResolution(sized(width: 1920)), isFalse);
      expect(isHighResolution(sized(width: 0, height: 0)), isFalse);
      expect(isHighResolution(sized(width: -1, height: -1)), isFalse);
    });
  });
}

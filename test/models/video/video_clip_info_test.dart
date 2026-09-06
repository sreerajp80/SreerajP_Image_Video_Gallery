import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/video/video_clip_info.dart';

void main() {
  group('rotation', () {
    test('a quarter turn swaps the width and the height on screen', () {
      const info = VideoClipInfo(
        width: 1920,
        height: 1080,
        rotationDegrees: 90,
      );

      expect(info.displayWidth, 1080);
      expect(info.displayHeight, 1920);
    });

    test('a half turn leaves the shape alone', () {
      const info = VideoClipInfo(
        width: 1920,
        height: 1080,
        rotationDegrees: 180,
      );

      expect(info.displayWidth, 1920);
      expect(info.displayHeight, 1080);
    });
  });

  group('isUsable', () {
    test('a clip with a length can be worked on', () {
      const info = VideoClipInfo(durationMs: 5000);
      expect(info.isUsable, isTrue);
    });

    test('a clip the platform said nothing about cannot', () {
      expect(VideoClipInfo.unknown.isUsable, isFalse);
    });
  });

  group('fromMap', () {
    test('a full map is read straight through', () {
      final info = VideoClipInfo.fromMap(<String, dynamic>{
        'durationMs': 4200,
        'width': 640,
        'height': 480,
        'rotationDegrees': 270,
        'frameRate': 29.97,
        'hasAudio': true,
      });

      expect(info.durationMs, 4200);
      expect(info.width, 640);
      expect(info.height, 480);
      expect(info.rotationDegrees, 270);
      expect(info.frameRate, closeTo(29.97, 0.001));
      expect(info.hasAudio, isTrue);
    });

    test('a map with nothing in it gives zeros rather than throwing', () {
      final info = VideoClipInfo.fromMap(<String, dynamic>{});

      expect(info, VideoClipInfo.unknown);
      expect(info.isUsable, isFalse);
    });
  });
}

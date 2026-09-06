import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/convert/image_output_format.dart';
import 'package:in_sreerajp_imgvidgal/services/video/video_frame_service.dart';
import 'package:in_sreerajp_imgvidgal/services/video/video_tools_channel.dart';
import 'package:path/path.dart' as p;

import 'fake_video_tools_channel.dart';

/// A small solid picture, encoded as JPEG, standing in for a real frame.
Uint8List sampleJpeg() {
  final image = img.Image(width: 32, height: 18, numChannels: 3);
  img.fill(image, color: img.ColorRgb8(10, 120, 200));
  return img.encodeJpg(image, quality: 90);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeVideoToolsChannel channel;
  late VideoFrameService service;
  late Directory directory;

  setUp(() async {
    channel = FakeVideoToolsChannel(frameBytes: sampleJpeg());
    service = VideoFrameService(channel: channel);
    directory = await Directory.systemTemp.createTemp('frame_test');
  });

  tearDown(() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  Future<String> writeClip(String name) async {
    final file = File(p.join(directory.path, name));
    await file.writeAsBytes(<int>[0, 1, 2]);
    return file.path;
  }

  group('previewFrame', () {
    test('the preview asks for a shrunken frame', () async {
      final source = await writeClip('CLIP.mp4');

      await service.previewFrame(sourcePath: source, positionMs: 1500);

      expect(channel.requestedPositions.single, 1500);
      expect(
        channel.requestedMaxSides.single,
        AppConstants.framePreviewMaxSide,
      );
    });

    test('a frame the platform refuses is reported', () async {
      final source = await writeClip('CLIP_2.mp4');
      channel.frameBytes = null;

      expect(
        () => service.previewFrame(sourcePath: source, positionMs: 0),
        throwsA(isA<VideoToolsException>()),
      );
    });
  });

  group('saveFrame', () {
    test('a JPEG frame is written straight out beside the clip', () async {
      final source = await writeClip('CLIP_3.mp4');

      final result = await service.saveFrame(
        sourcePath: source,
        positionMs: 2000,
        format: ImageOutputFormat.jpeg,
      );

      expect(p.basename(result.path), 'CLIP_3_frame1.jpg');
      expect(result.positionMs, 2000);
      expect(await File(result.path).exists(), isTrue);
      // A saved frame keeps its full size, so no shrinking is asked for.
      expect(channel.requestedMaxSides.single, 0);
    });

    test('a PNG frame is re-encoded before it is written', () async {
      final source = await writeClip('CLIP_4.mp4');

      final result = await service.saveFrame(
        sourcePath: source,
        positionMs: 0,
        format: ImageOutputFormat.png,
      );

      expect(p.basename(result.path), 'CLIP_4_frame1.png');

      final written = await File(result.path).readAsBytes();
      expect(written.sublist(1, 4), <int>[0x50, 0x4E, 0x47]);
    });

    test('the clip itself is never changed', () async {
      final source = await writeClip('CLIP_5.mp4');
      final before = await File(source).readAsBytes();

      await service.saveFrame(sourcePath: source, positionMs: 500);

      expect(await File(source).readAsBytes(), before);
    });

    test('a second save gets its own name', () async {
      final source = await writeClip('CLIP_6.mp4');

      final first = await service.saveFrame(sourcePath: source, positionMs: 0);
      final second = await service.saveFrame(
        sourcePath: source,
        positionMs: 100,
      );

      expect(p.basename(first.path), 'CLIP_6_frame1.jpg');
      expect(p.basename(second.path), 'CLIP_6_frame2.jpg');
    });
  });
}

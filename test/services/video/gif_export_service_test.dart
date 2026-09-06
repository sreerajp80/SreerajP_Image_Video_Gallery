import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:in_sreerajp_imgvidgal/models/video/gif_export_options.dart';
import 'package:in_sreerajp_imgvidgal/models/video/trim_range.dart';
import 'package:in_sreerajp_imgvidgal/services/video/gif_export_service.dart';
import 'package:in_sreerajp_imgvidgal/services/video/video_tools_channel.dart';
import 'package:path/path.dart' as p;

import 'fake_video_tools_channel.dart';

/// A small solid picture, encoded as JPEG, standing in for a real frame.
Uint8List sampleJpeg({int width = 64, int height = 36}) {
  final image = img.Image(width: width, height: height, numChannels: 3);
  img.fill(image, color: img.ColorRgb8(40, 160, 90));
  return img.encodeJpg(image, quality: 90);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeVideoToolsChannel channel;
  late GifExportService service;
  late Directory directory;

  setUp(() async {
    channel = FakeVideoToolsChannel(frameBytes: sampleJpeg());
    service = GifExportService(channel: channel);
    directory = await Directory.systemTemp.createTemp('gif_test');
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

  group('encode', () {
    test('the frames become a real GIF', () {
      final bytes = GifExportService.encode(
        GifEncodeJob(
          frames: <Uint8List>[sampleJpeg(), sampleJpeg()],
          maxSide: 320,
          frameDelayMs: 100,
          loop: true,
        ),
      );

      // Every GIF file starts with "GIF8".
      expect(String.fromCharCodes(bytes.sublist(0, 4)), 'GIF8');
    });

    test('the frames are shrunk to the chosen longest side', () {
      final bytes = GifExportService.encode(
        GifEncodeJob(
          frames: <Uint8List>[sampleJpeg(width: 1280, height: 720)],
          maxSide: 240,
          frameDelayMs: 100,
          loop: true,
        ),
      );

      final decoded = img.decodeGif(bytes);
      expect(decoded, isNotNull);
      expect(decoded!.width, 240);
      expect(decoded.height, 135);
    });

    test('a frame that cannot be read is skipped, not fatal', () {
      final bytes = GifExportService.encode(
        GifEncodeJob(
          frames: <Uint8List>[
            sampleJpeg(),
            Uint8List.fromList(List<int>.filled(20, 9)),
          ],
          maxSide: 320,
          frameDelayMs: 100,
          loop: true,
        ),
      );

      expect(String.fromCharCodes(bytes.sublist(0, 4)), 'GIF8');
    });

    test('frames that are all unreadable are refused', () {
      expect(
        () => GifExportService.encode(
          GifEncodeJob(
            frames: <Uint8List>[Uint8List.fromList(List<int>.filled(20, 9))],
            maxSide: 320,
            frameDelayMs: 100,
            loop: true,
          ),
        ),
        throwsA(isA<VideoToolsException>()),
      );
    });
  });

  group('export', () {
    test('the GIF is written beside the clip, which is untouched', () async {
      final source = await writeClip('CLIP.mp4');
      final before = await File(source).readAsBytes();

      final result = await service.export(
        sourcePath: source,
        options: const GifExportOptions(
          frameRate: 5,
          range: TrimRange(startMs: 0, endMs: 600),
        ),
        clipDurationMs: 5000,
      );

      expect(p.basename(result.path), 'CLIP_gif1.gif');
      expect(result.frameCount, 3);
      expect(await File(result.path).exists(), isTrue);
      expect(await File(source).readAsBytes(), before);
    });

    test('the planned times are what the platform is asked for', () async {
      final source = await writeClip('CLIP_2.mp4');

      await service.export(
        sourcePath: source,
        options: const GifExportOptions(
          frameRate: 5,
          range: TrimRange(startMs: 1000, endMs: 1600),
        ),
        clipDurationMs: 5000,
      );

      expect(channel.requestedPositions, <int>[1000, 1200, 1400]);
    });

    test('one refused frame does not cost the whole GIF', () async {
      final source = await writeClip('CLIP_3.mp4');
      channel.failingPositions = <int>{200};

      final result = await service.export(
        sourcePath: source,
        options: const GifExportOptions(
          frameRate: 5,
          range: TrimRange(startMs: 0, endMs: 600),
        ),
        clipDurationMs: 5000,
      );

      expect(result.frameCount, 2);
    });

    test('a clip that gives no frames at all is reported', () async {
      final source = await writeClip('CLIP_4.mp4');
      channel.frameBytes = null;

      expect(
        () => service.export(
          sourcePath: source,
          options: const GifExportOptions(
            frameRate: 5,
            range: TrimRange(startMs: 0, endMs: 600),
          ),
          clipDurationMs: 5000,
        ),
        throwsA(isA<VideoToolsException>()),
      );
    });

    test('a clip with no length is refused', () async {
      final source = await writeClip('CLIP_5.mp4');

      expect(
        () => service.export(
          sourcePath: source,
          options: const GifExportOptions(),
          clipDurationMs: 0,
        ),
        throwsA(isA<VideoToolsException>()),
      );
    });

    test('progress is reported once per planned frame', () async {
      final source = await writeClip('CLIP_6.mp4');
      final seen = <int>[];

      await service.export(
        sourcePath: source,
        options: const GifExportOptions(
          frameRate: 5,
          range: TrimRange(startMs: 0, endMs: 600),
        ),
        clipDurationMs: 5000,
        onProgress: (done, total) {
          seen.add(done);
          expect(total, 3);
        },
      );

      expect(seen, <int>[1, 2, 3]);
    });
  });
}

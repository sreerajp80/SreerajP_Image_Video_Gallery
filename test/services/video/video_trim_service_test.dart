import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/video/trim_range.dart';
import 'package:in_sreerajp_imgvidgal/services/video/video_tools_channel.dart';
import 'package:in_sreerajp_imgvidgal/services/video/video_trim_service.dart';
import 'package:path/path.dart' as p;

import 'fake_video_tools_channel.dart';

void main() {
  late FakeVideoToolsChannel channel;
  late VideoTrimService service;
  late Directory directory;

  setUp(() async {
    channel = FakeVideoToolsChannel();
    service = VideoTrimService(channel: channel);
    directory = await Directory.systemTemp.createTemp('trim_test');
  });

  tearDown(() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  Future<String> writeClip(String name) async {
    final file = File(p.join(directory.path, name));
    await file.writeAsBytes(<int>[0, 1, 2, 3, 4]);
    return file.path;
  }

  group('clampRange', () {
    test('a range inside the clip is left alone', () {
      final range = service.clampRange(
        range: const TrimRange(startMs: 1000, endMs: 4000),
        clipDurationMs: 10000,
      );

      expect(range, const TrimRange(startMs: 1000, endMs: 4000));
    });

    test('an end past the clip is pulled back to the clip end', () {
      final range = service.clampRange(
        range: const TrimRange(startMs: 0, endMs: 999999),
        clipDurationMs: 8000,
      );

      expect(range.endMs, 8000);
    });

    test('a negative start is pulled up to zero', () {
      final range = service.clampRange(
        range: const TrimRange(startMs: -500, endMs: 3000),
        clipDurationMs: 8000,
      );

      expect(range.startMs, 0);
    });

    test('a slice that is too short is grown forwards', () {
      final range = service.clampRange(
        range: const TrimRange(startMs: 1000, endMs: 1050),
        clipDurationMs: 10000,
      );

      expect(range.startMs, 1000);
      expect(range.durationMs, AppConstants.trimMinDurationMs);
      expect(range.isValid, isTrue);
    });

    test('near the end of a clip it is grown backwards instead', () {
      final range = service.clampRange(
        range: const TrimRange(startMs: 9990, endMs: 10000),
        clipDurationMs: 10000,
      );

      expect(range.endMs, 10000);
      expect(range.durationMs, AppConstants.trimMinDurationMs);
    });

    test('a clip with no length gives an empty range', () {
      final range = service.clampRange(
        range: const TrimRange(startMs: 0, endMs: 5000),
        clipDurationMs: 0,
      );

      expect(range.durationMs, 0);
      expect(range.isValid, isFalse);
    });
  });

  group('trim', () {
    test('the clamped range is what reaches the platform', () async {
      final source = await writeClip('CLIP.mp4');

      await service.trim(
        sourcePath: source,
        range: const TrimRange(startMs: -200, endMs: 999999),
        clipDurationMs: 6000,
      );

      expect(channel.requestedTrims.single, <int>[0, 6000]);
    });

    test(
      'the new clip is written beside the original, which is untouched',
      () async {
        final source = await writeClip('CLIP_2.mp4');
        final before = await File(source).readAsBytes();

        final result = await service.trim(
          sourcePath: source,
          range: const TrimRange(startMs: 1000, endMs: 4000),
          clipDurationMs: 8000,
        );

        expect(p.basename(result.path), 'CLIP_2_trim1.mp4');
        expect(await File(result.path).exists(), isTrue);
        expect(await File(source).readAsBytes(), before);
      },
    );

    test('the container of a known type is kept', () async {
      final source = await writeClip('CLIP_3.3gp');

      final result = await service.trim(
        sourcePath: source,
        range: const TrimRange(startMs: 0, endMs: 3000),
        clipDurationMs: 8000,
      );

      expect(p.extension(result.path), '.3gp');
    });

    test('an unusual container falls back to MP4', () async {
      final source = await writeClip('CLIP_4.mkv');

      final result = await service.trim(
        sourcePath: source,
        range: const TrimRange(startMs: 0, endMs: 3000),
        clipDurationMs: 8000,
      );

      expect(p.extension(result.path), '.mp4');
    });

    test(
      'a clip with no length is refused before the platform is called',
      () async {
        final source = await writeClip('CLIP_5.mp4');

        expect(
          () => service.trim(
            sourcePath: source,
            range: const TrimRange(startMs: 0, endMs: 1000),
            clipDurationMs: 0,
          ),
          throwsA(isA<VideoToolsException>()),
        );
        expect(channel.requestedTrims, isEmpty);
      },
    );

    test('a platform failure is reported rather than swallowed', () async {
      final source = await writeClip('CLIP_6.mp4');
      channel.failTrim = true;

      expect(
        () => service.trim(
          sourcePath: source,
          range: const TrimRange(startMs: 0, endMs: 3000),
          clipDurationMs: 8000,
        ),
        throwsA(isA<VideoToolsException>()),
      );
    });
  });
}

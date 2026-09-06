import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/services/convert/output_naming_service.dart';
import 'package:path/path.dart' as p;

void main() {
  const service = OutputNamingService();

  group('buildOutputPath', () {
    test('the first copy gets version one beside the original', () {
      final path = service.buildOutputPath(
        sourcePath: p.join('photos', 'IMG_0001.jpg'),
        suffix: AppConstants.convertOutputSuffix,
        extension: 'webp',
        exists: (_) => false,
      );

      expect(p.basename(path), 'IMG_0001_conv1.webp');
      expect(p.dirname(path), 'photos');
    });

    test('the version number climbs past names already taken', () {
      final taken = <String>{
        p.join('photos', 'IMG_0001_conv1.png'),
        p.join('photos', 'IMG_0001_conv2.png'),
      };

      final path = service.buildOutputPath(
        sourcePath: p.join('photos', 'IMG_0001.jpg'),
        suffix: AppConstants.convertOutputSuffix,
        extension: 'png',
        exists: taken.contains,
      );

      expect(p.basename(path), 'IMG_0001_conv3.png');
    });

    test('a leading dot on the extension is not doubled', () {
      final path = service.buildOutputPath(
        sourcePath: p.join('clips', 'CLIP.mp4'),
        suffix: AppConstants.trimOutputSuffix,
        extension: '.mp4',
        exists: (_) => false,
      );

      expect(p.basename(path), 'CLIP_trim1.mp4');
    });

    test('an empty source path is refused', () {
      expect(
        () => service.buildOutputPath(
          sourcePath: '',
          suffix: '_conv',
          extension: 'jpg',
          exists: (_) => false,
        ),
        throwsA(isA<OutputSaveException>()),
      );
    });

    test(
      'it gives up rather than looping forever when every name is taken',
      () {
        expect(
          () => service.buildOutputPath(
            sourcePath: p.join('photos', 'IMG.jpg'),
            suffix: '_conv',
            extension: 'jpg',
            exists: (_) => true,
          ),
          throwsA(isA<OutputSaveException>()),
        );
      },
    );
  });

  group('isConvertibleSize', () {
    test('a normal file is allowed', () {
      expect(service.isConvertibleSize(5 * 1024 * 1024), isTrue);
    });

    test('an empty file is refused', () {
      expect(service.isConvertibleSize(0), isFalse);
    });

    test('a file over the limit is refused', () {
      expect(
        service.isConvertibleSize(AppConstants.convertMaxSourceBytes + 1),
        isFalse,
      );
    });
  });

  group('saveBytes', () {
    late Directory directory;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('naming_test');
    });

    tearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });

    test(
      'the copy is written beside the source and the source is untouched',
      () async {
        final source = File(p.join(directory.path, 'IMG_0001.jpg'));
        await source.writeAsBytes(<int>[1, 2, 3]);

        final written = await service.saveBytes(
          sourcePath: source.path,
          suffix: AppConstants.convertOutputSuffix,
          extension: 'png',
          bytes: Uint8List.fromList(<int>[9, 8, 7, 6]),
        );

        expect(p.basename(written.path), 'IMG_0001_conv1.png');
        expect(await written.readAsBytes(), <int>[9, 8, 7, 6]);
        expect(await source.readAsBytes(), <int>[1, 2, 3]);
      },
    );

    test('a second save does not overwrite the first copy', () async {
      final source = File(p.join(directory.path, 'IMG_0002.jpg'));
      await source.writeAsBytes(<int>[1]);

      final first = await service.saveBytes(
        sourcePath: source.path,
        suffix: AppConstants.convertOutputSuffix,
        extension: 'png',
        bytes: Uint8List.fromList(<int>[1]),
      );
      final second = await service.saveBytes(
        sourcePath: source.path,
        suffix: AppConstants.convertOutputSuffix,
        extension: 'png',
        bytes: Uint8List.fromList(<int>[2]),
      );

      expect(p.basename(first.path), 'IMG_0002_conv1.png');
      expect(p.basename(second.path), 'IMG_0002_conv2.png');
      expect(await first.exists(), isTrue);
    });

    test('there is nothing to save when the bytes are empty', () async {
      final source = File(p.join(directory.path, 'IMG_0003.jpg'));
      await source.writeAsBytes(<int>[1]);

      expect(
        () => service.saveBytes(
          sourcePath: source.path,
          suffix: '_conv',
          extension: 'png',
          bytes: Uint8List(0),
        ),
        throwsA(isA<OutputSaveException>()),
      );
    });

    test('reserveOutputPath picks a free name without writing to it', () {
      final source = File(p.join(directory.path, 'CLIP.mp4'));
      source.writeAsBytesSync(<int>[1]);

      final path = service.reserveOutputPath(
        sourcePath: source.path,
        suffix: AppConstants.trimOutputSuffix,
        extension: 'mp4',
      );

      expect(p.basename(path), 'CLIP_trim1.mp4');
      expect(File(path).existsSync(), isFalse);
    });
  });
}

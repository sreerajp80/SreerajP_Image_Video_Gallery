import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/services/editor/editor_save_service.dart';
import 'package:in_sreerajp_imgvidgal/services/editor/image_render_pipeline.dart';
import 'package:path/path.dart' as p;

void main() {
  const service = EditorSaveService();

  group('buildOutputPath', () {
    test('the first copy gets version one beside the original', () {
      final path = service.buildOutputPath(
        sourcePath: p.join('photos', 'IMG_0001.jpg'),
        format: RenderFormat.jpeg,
        exists: (_) => false,
      );

      expect(p.basename(path), 'IMG_0001_edit1.jpg');
      expect(p.dirname(path), 'photos');
    });

    test('the version number climbs past names already taken', () {
      final taken = <String>{
        p.join('photos', 'IMG_0001_edit1.jpg'),
        p.join('photos', 'IMG_0001_edit2.jpg'),
      };

      final path = service.buildOutputPath(
        sourcePath: p.join('photos', 'IMG_0001.jpg'),
        format: RenderFormat.jpeg,
        exists: taken.contains,
      );

      expect(p.basename(path), 'IMG_0001_edit3.jpg');
    });

    test('the extension follows the render format, not the original', () {
      final path = service.buildOutputPath(
        sourcePath: p.join('photos', 'scan.webp'),
        format: RenderFormat.png,
        exists: (_) => false,
      );

      expect(p.basename(path), 'scan_edit1.png');
    });

    test('the new name is never the original name', () {
      const source = 'IMG_0001.jpg';
      final path = service.buildOutputPath(
        sourcePath: source,
        format: RenderFormat.jpeg,
        exists: (_) => false,
      );

      expect(p.equals(path, source), isFalse);
    });

    test('it gives up cleanly when every version is taken', () {
      expect(
        () => service.buildOutputPath(
          sourcePath: 'IMG_0001.jpg',
          format: RenderFormat.jpeg,
          exists: (_) => true,
        ),
        throwsA(isA<EditorSaveException>()),
      );
    });
  });

  group('isEditableSize', () {
    test('an ordinary photo is editable', () {
      expect(service.isEditableSize(4 * 1024 * 1024), isTrue);
    });

    test('an empty file is not editable', () {
      expect(service.isEditableSize(0), isFalse);
    });

    test('a file over the limit is not editable', () {
      expect(
        service.isEditableSize(AppConstants.editorMaxSourceBytes + 1),
        isFalse,
      );
    });
  });

  group('saveCopy', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('editor_save_test');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('the copy is written and the original is left untouched', () async {
      final source = File(p.join(tempDir.path, 'IMG_0001.jpg'));
      final originalBytes = Uint8List.fromList(<int>[1, 2, 3, 4]);
      await source.writeAsBytes(originalBytes);

      final outcome = await service.saveCopy(
        sourcePath: source.path,
        bytes: Uint8List.fromList(<int>[9, 8, 7]),
        format: RenderFormat.jpeg,
      );

      expect(p.basename(outcome.path), 'IMG_0001_edit1.jpg');
      expect(outcome.sizeBytes, 3);
      expect(await File(outcome.path).readAsBytes(), <int>[9, 8, 7]);
      // The whole point of the phase: the original still has its own bytes.
      expect(await source.readAsBytes(), originalBytes);
    });

    test('saving twice makes two copies, not one overwrite', () async {
      final source = File(p.join(tempDir.path, 'IMG_0002.jpg'));
      await source.writeAsBytes(Uint8List.fromList(<int>[1]));

      final first = await service.saveCopy(
        sourcePath: source.path,
        bytes: Uint8List.fromList(<int>[1, 1]),
        format: RenderFormat.jpeg,
      );
      final second = await service.saveCopy(
        sourcePath: source.path,
        bytes: Uint8List.fromList(<int>[2, 2]),
        format: RenderFormat.jpeg,
      );

      expect(first.path, isNot(second.path));
      expect(await File(first.path).exists(), isTrue);
      expect(await File(second.path).exists(), isTrue);
    });

    test('an empty render is refused rather than written', () async {
      final source = File(p.join(tempDir.path, 'IMG_0003.jpg'));
      await source.writeAsBytes(Uint8List.fromList(<int>[1]));

      expect(
        () => service.saveCopy(
          sourcePath: source.path,
          bytes: Uint8List(0),
          format: RenderFormat.jpeg,
        ),
        throwsA(isA<EditorSaveException>()),
      );
    });

    test('no stray staging file is left behind', () async {
      final source = File(p.join(tempDir.path, 'IMG_0004.jpg'));
      await source.writeAsBytes(Uint8List.fromList(<int>[1]));

      await service.saveCopy(
        sourcePath: source.path,
        bytes: Uint8List.fromList(<int>[5, 5, 5]),
        format: RenderFormat.jpeg,
      );

      final leftovers = tempDir
          .listSync()
          .map((entity) => p.basename(entity.path))
          .where((name) => name.contains('.tmp_'));

      expect(leftovers, isEmpty);
    });
  });
}

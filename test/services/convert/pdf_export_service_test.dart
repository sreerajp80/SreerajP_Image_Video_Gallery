import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:in_sreerajp_imgvidgal/models/convert/pdf_export_options.dart';
import 'package:in_sreerajp_imgvidgal/services/convert/pdf_export_service.dart';
import 'package:path/path.dart' as p;

/// A small solid picture, encoded as PNG.
Uint8List samplePng({int width = 60, int height = 40}) {
  final image = img.Image(width: width, height: height, numChannels: 3);
  img.fill(image, color: img.ColorRgb8(30, 90, 180));
  return img.encodePng(image);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final service = PdfExportService();
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('pdf_export_test');
  });

  tearDown(() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  Future<String> writePhoto(String name, {Uint8List? bytes}) async {
    final file = File(p.join(directory.path, name));
    await file.writeAsBytes(bytes ?? samplePng());
    return file.path;
  }

  group('export', () {
    test('a real PDF is written beside the first photo', () async {
      final first = await writePhoto('IMG_0001.png');
      final second = await writePhoto('IMG_0002.png');

      final result = await service.export(
        imagePaths: <String>[first, second],
        options: const PdfExportOptions(),
      );

      expect(result.pageCount, 2);
      expect(result.skippedCount, 0);
      expect(p.basename(result.path), 'IMG_0001_album1.pdf');
      expect(p.dirname(result.path), directory.path);

      final written = await File(result.path).readAsBytes();
      // Every PDF file starts with these four characters.
      expect(String.fromCharCodes(written.sublist(0, 4)), '%PDF');
      expect(written.length, result.bytes);
    });

    test('the original photos are left exactly as they were', () async {
      final path = await writePhoto('IMG_0003.png');
      final before = await File(path).readAsBytes();

      await service.export(
        imagePaths: <String>[path],
        options: const PdfExportOptions(),
      );

      expect(await File(path).readAsBytes(), before);
    });

    test('a photo that cannot be read is skipped, not fatal', () async {
      final good = await writePhoto('IMG_0004.png');
      final broken = await writePhoto(
        'BROKEN.png',
        bytes: Uint8List.fromList(List<int>.filled(40, 5)),
      );

      final result = await service.export(
        imagePaths: <String>[good, broken],
        options: const PdfExportOptions(),
      );

      expect(result.pageCount, 1);
      expect(result.skippedCount, 1);
    });

    test('a missing file is skipped as well', () async {
      final good = await writePhoto('IMG_0005.png');
      final missing = p.join(directory.path, 'NOT_THERE.png');

      final result = await service.export(
        imagePaths: <String>[good, missing],
        options: const PdfExportOptions(),
      );

      expect(result.pageCount, 1);
      expect(result.skippedCount, 1);
    });

    test('progress is reported once per chosen photo', () async {
      final paths = <String>[
        await writePhoto('IMG_0006.png'),
        await writePhoto('IMG_0007.png'),
        await writePhoto('IMG_0008.png'),
      ];

      final seen = <int>[];
      await service.export(
        imagePaths: paths,
        options: const PdfExportOptions(),
        onProgress: (done, total) {
          seen.add(done);
          expect(total, 3);
        },
      );

      expect(seen, <int>[1, 2, 3]);
    });

    test('an empty selection is refused', () async {
      expect(
        () => service.export(
          imagePaths: const <String>[],
          options: const PdfExportOptions(),
        ),
        throwsA(isA<PdfExportException>()),
      );
    });

    test('a selection where nothing can be read is refused', () async {
      final broken = await writePhoto(
        'ALL_BAD.png',
        bytes: Uint8List.fromList(List<int>.filled(40, 5)),
      );

      expect(
        () => service.export(
          imagePaths: <String>[broken],
          options: const PdfExportOptions(),
        ),
        throwsA(isA<PdfExportException>()),
      );
    });

    test('a fit-to-photo document is written just as happily', () async {
      final path = await writePhoto('IMG_0009.png');

      final result = await service.export(
        imagePaths: <String>[path],
        options: const PdfExportOptions(pageSize: PdfPageSize.fitImage),
      );

      expect(result.pageCount, 1);
      expect(await File(result.path).exists(), isTrue);
    });
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/pdf/pdf_extraction_result.dart';
import 'package:in_sreerajp_imgvidgal/models/pdf/pdf_image_entry.dart';
import 'package:in_sreerajp_imgvidgal/services/backup/document_picker_channel.dart';
import 'package:in_sreerajp_imgvidgal/services/pdf/pdf_extraction_service.dart';

import '../media/fake_media_store_channel.dart';
import 'pdf_test_files.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('in.sreerajp.imgvidgal/documents');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late Directory workspace;
  late FakeMediaStoreChannel mediaStore;
  late PdfExtractionService service;

  /// Files the fake picker handed out, so the test can check they are gone.
  final handedOut = <String>[];
  final calls = <String>[];

  /// What the fake picker should do next.
  String? Function()? onCopyToCache;
  String? onOpenDocument;

  setUp(() {
    workspace = Directory.systemTemp.createTempSync('pdf_service_test');
    mediaStore = FakeMediaStoreChannel();
    service = PdfExtractionService(
      picker: DocumentPickerChannel(channel: channel),
      mediaStore: mediaStore,
    );

    handedOut.clear();
    calls.clear();
    onCopyToCache = null;
    onOpenDocument = 'content://documents/1';

    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);

      switch (call.method) {
        case 'openDocument':
          return onOpenDocument;
        case 'documentInfo':
          return <String, Object?>{'name': 'holiday.pdf', 'sizeBytes': 1234};
        case 'copyToCache':
          final path = onCopyToCache?.call();
          if (path != null) handedOut.add(path);
          return path;
      }
      return null;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    if (workspace.existsSync()) workspace.deleteSync(recursive: true);
  });

  /// Writes [bytes] to a real file the fake picker can hand back.
  String writeFile(Uint8List bytes, [String name = 'picked.pdf']) {
    final file = File('${workspace.path}${Platform.pathSeparator}$name');
    file.writeAsBytesSync(bytes);
    return file.path;
  }

  Uint8List onePdfImage() {
    return PdfTestFiles.withImage(
      dictionary:
          '/Type /XObject /Subtype /Image /Width 2 /Height 2 '
          '/BitsPerComponent 8 /ColorSpace /DeviceRGB /Filter /FlateDecode',
      stream: PdfTestFiles.flateRgb(2, 2),
    );
  }

  group('picking', () {
    test('backing out of the picker gives null, not an error', () async {
      onOpenDocument = null;
      expect(await service.pickPdf(), isNull);
    });

    test('a picked file comes back with its name and size', () async {
      final picked = await service.pickPdf();
      expect(picked?.name, 'holiday.pdf');
      expect(picked?.sizeBytes, 1234);
    });
  });

  group('reading', () {
    test('the images in a real PDF are found', () async {
      onCopyToCache = () => writeFile(onePdfImage());

      final result = await service.readImages('content://documents/1');
      expect(result.isRefused, isFalse);
      expect(result.extractable, hasLength(1));
    });

    // The picked file is the user's document. A copy of it must not be left
    // sitting inside the app once the reading is done.
    test('the app-private copy is deleted afterwards', () async {
      onCopyToCache = () => writeFile(onePdfImage());

      await service.readImages('content://documents/1');

      expect(handedOut, hasLength(1));
      expect(File(handedOut.single).existsSync(), isFalse);
    });

    test('the copy is deleted even when the file is not a PDF', () async {
      onCopyToCache = () =>
          writeFile(Uint8List.fromList(latin1.encode('just some text')));

      final result = await service.readImages('content://documents/1');

      expect(result.refusal, PdfRefusalReason.notAPdf);
      expect(File(handedOut.single).existsSync(), isFalse);
    });

    test('a file too large to copy is refused as too large', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'copyToCache') {
          throw PlatformException(code: 'too_large', message: 'nope');
        }
        return null;
      });

      final result = await service.readImages('content://documents/1');
      expect(result.refusal, PdfRefusalReason.fileTooLarge);
    });

    test('an unreadable file is refused, not thrown on', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'copyToCache') {
          throw PlatformException(code: 'unreadable', message: 'gone');
        }
        return null;
      });

      expect(
        (await service.readImages('content://documents/1')).refusal,
        PdfRefusalReason.unreadable,
      );
    });

    test('a copy that never arrives is refused', () async {
      onCopyToCache = () => null;
      expect(
        (await service.readImages('content://documents/1')).refusal,
        PdfRefusalReason.unreadable,
      );
    });

    test('an empty uri never reaches the platform', () async {
      final result = await service.readImages('');
      expect(result.refusal, PdfRefusalReason.notAPdf);
      expect(calls, isEmpty);
    });
  });

  group('saving', () {
    PdfImageEntry entry(int number) => PdfImageEntry(
      objectNumber: number,
      width: 2,
      height: 2,
      bytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
      format: PdfImageFormat.png,
    );

    test('each picture is published, named after the PDF', () async {
      final summary = await service.saveImages(<PdfImageEntry>[
        entry(4),
        entry(5),
      ], sourceName: 'holiday.pdf');

      expect(summary.savedCount, 2);
      expect(summary.allSaved, isTrue);
      expect(mediaStore.publishedNames, hasLength(2));
      expect(mediaStore.publishedNames.first, startsWith('holiday_4'));
      expect(mediaStore.publishedNames.first, endsWith('.png'));
    });

    test('an awkward file name is made safe', () async {
      await service.saveImages(<PdfImageEntry>[
        entry(1),
      ], sourceName: '../../etc/pass wd?.pdf');

      final name = mediaStore.publishedNames.single;
      expect(name, isNot(contains('/')));
      expect(name, isNot(contains('..')));
      expect(name, isNot(contains('?')));
    });

    test('a PDF with no usable name still gives a name', () async {
      await service.saveImages(<PdfImageEntry>[entry(1)], sourceName: '');
      expect(mediaStore.publishedNames.single, startsWith('pdf_1'));
    });

    test('a skipped entry is counted as failed, not published', () async {
      final summary = await service.saveImages(<PdfImageEntry>[
        const PdfImageEntry.skipped(
          objectNumber: 9,
          width: 2,
          height: 2,
          reason: PdfImageSkipReason.unsupportedFilter,
        ),
      ]);

      expect(summary.savedCount, 0);
      expect(summary.failedCount, 1);
      expect(mediaStore.publishedNames, isEmpty);
    });

    // One bad picture must not lose the good ones alongside it.
    test('a publish that fails does not sink the whole batch', () async {
      mediaStore.publishThrows = true;

      final summary = await service.saveImages(<PdfImageEntry>[
        entry(1),
        entry(2),
      ]);

      expect(summary.savedCount, 0);
      expect(summary.failedCount, 2);
      expect(summary.allSaved, isFalse);
    });

    test('saving nothing is not an error', () async {
      final summary = await service.saveImages(const <PdfImageEntry>[]);
      expect(summary.savedCount, 0);
      expect(summary.allSaved, isTrue);
    });
  });
}

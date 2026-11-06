import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/pdf/pdf_extraction_result.dart';
import 'package:in_sreerajp_imgvidgal/models/pdf/pdf_image_entry.dart';
import 'package:in_sreerajp_imgvidgal/providers/pdf_tools_providers.dart';
import 'package:in_sreerajp_imgvidgal/services/backup/document_picker_channel.dart';
import 'package:in_sreerajp_imgvidgal/services/pdf/pdf_extraction_service.dart';

/// A PDF with two saveable pictures and one that cannot be saved.
class _FakePdfService implements PdfExtractionService {
  bool cancelPick = false;
  bool failRead = false;
  List<int> savedObjects = <int>[];
  String savedName = '';

  @override
  Future<PickedDocument?> pickPdf() async {
    if (cancelPick) return null;
    return const PickedDocument(uri: 'content://doc', name: 'Notes.pdf');
  }

  @override
  Future<PdfExtractionResult> readImages(String uri) async {
    if (failRead) throw StateError('broken file');
    return PdfExtractionResult(
      entries: <PdfImageEntry>[
        PdfImageEntry(
          objectNumber: 1,
          width: 10,
          height: 10,
          bytes: Uint8List.fromList(<int>[1]),
        ),
        PdfImageEntry(
          objectNumber: 2,
          width: 10,
          height: 10,
          bytes: Uint8List.fromList(<int>[2]),
        ),
        const PdfImageEntry(
          objectNumber: 3,
          width: 10,
          height: 10,
          skipReason: PdfImageSkipReason.unsupportedFilter,
        ),
      ],
    );
  }

  @override
  Future<PdfSaveSummary> saveImages(
    List<PdfImageEntry> entries, {
    String sourceName = '',
  }) async {
    savedObjects = entries.map((e) => e.objectNumber).toList();
    savedName = sourceName;
    return const PdfSaveSummary();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakePdfService service;
  late ProviderContainer container;

  setUp(() {
    service = _FakePdfService();
    container = ProviderContainer(
      overrides: <Override>[
        pdfExtractionServiceProvider.overrideWithValue(service),
      ],
    );
  });

  tearDown(() => container.dispose());

  PdfExtractionController controller() =>
      container.read(pdfExtractionControllerProvider.notifier);

  test('backing out of the picker changes nothing', () async {
    service.cancelPick = true;

    await controller().pickAndRead();

    expect(container.read(pdfExtractionControllerProvider).value, isNull);
    expect(container.read(pickedPdfNameProvider), isEmpty);
  });

  test('every saveable picture starts ticked', () async {
    await controller().pickAndRead();

    expect(container.read(pickedPdfNameProvider), 'Notes.pdf');
    expect(container.read(selectedPdfImagesProvider), <int>{1, 2});
  });

  test('only ticked pictures are saved, under the PDF name', () async {
    await controller().pickAndRead();
    controller().toggle(1);

    await controller().saveSelected();

    expect(service.savedObjects, <int>[2]);
    expect(service.savedName, 'Notes.pdf');
  });

  test('nothing ticked saves nothing', () async {
    await controller().pickAndRead();
    controller()
      ..toggle(1)
      ..toggle(2);

    await controller().saveSelected();

    expect(service.savedObjects, isEmpty);
  });

  test('a broken file gives an error state', () async {
    service.failRead = true;

    await controller().pickAndRead();

    expect(container.read(pdfExtractionControllerProvider).hasError, isTrue);
  });

  test('reset clears the file, the name and the ticks', () async {
    await controller().pickAndRead();
    controller().reset();

    expect(container.read(pdfExtractionControllerProvider).value, isNull);
    expect(container.read(pickedPdfNameProvider), isEmpty);
    expect(container.read(selectedPdfImagesProvider), isEmpty);
  });
}

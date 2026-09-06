import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/models/pdf/pdf_extraction_result.dart';
import 'package:in_sreerajp_imgvidgal/models/pdf/pdf_image_entry.dart';
import 'package:in_sreerajp_imgvidgal/providers/backup_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/services/pdf/pdf_extraction_service.dart';
import 'package:in_sreerajp_imgvidgal/services/pdf/pdf_image_extractor.dart';

/// Reads the image objects out of PDF bytes.
final pdfImageExtractorProvider = Provider<PdfImageExtractor>((ref) {
  return const PdfImageExtractor();
});

/// Picks a PDF, reads it, and saves the pictures the user keeps.
final pdfExtractionServiceProvider = Provider<PdfExtractionService>((ref) {
  return PdfExtractionService(
    // The same system file picker the backup screen uses, which is what lets
    // this feature exist with no storage permission at all.
    picker: ref.watch(documentPickerChannelProvider),
    mediaStore: ref.watch(mediaStoreChannelProvider),
    extractor: ref.watch(pdfImageExtractorProvider),
  );
});

/// The name of the PDF being looked at, for the screen's title.
final pickedPdfNameProvider = StateProvider<String>((ref) => '');

/// Which pictures the user has ticked to save.
///
/// Held by object number, because that is what stays the same between a
/// rebuild and a save.
final selectedPdfImagesProvider = StateProvider<Set<int>>((ref) => <int>{});

/// Picks a PDF and reads it.
class PdfExtractionController
    extends StateNotifier<AsyncValue<PdfExtractionResult?>> {
  final Ref _ref;

  PdfExtractionController(this._ref) : super(const AsyncValue.data(null));

  /// Asks for a PDF and reads every picture in it.
  ///
  /// Does nothing when the user backs out of the picker, which is a normal
  /// thing to do rather than a failure.
  Future<void> pickAndRead() async {
    final service = _ref.read(pdfExtractionServiceProvider);

    try {
      final picked = await service.pickPdf();
      if (picked == null) return;

      state = const AsyncValue.loading();
      _ref.read(pickedPdfNameProvider.notifier).state = picked.name;
      _ref.read(selectedPdfImagesProvider.notifier).state = <int>{};

      final result = await service.readImages(picked.uri);
      state = AsyncValue.data(result);

      // Everything that can be saved starts ticked: someone who opened this
      // screen wants the pictures, and unticking a few is less work than
      // ticking them all.
      _ref.read(selectedPdfImagesProvider.notifier).state = <int>{
        for (final entry in result.extractable) entry.objectNumber,
      };
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Ticks or unticks one picture.
  void toggle(int objectNumber) {
    final selected = Set<int>.from(_ref.read(selectedPdfImagesProvider));
    if (!selected.remove(objectNumber)) selected.add(objectNumber);
    _ref.read(selectedPdfImagesProvider.notifier).state = selected;
  }

  /// Saves the ticked pictures into the gallery.
  Future<PdfSaveSummary?> saveSelected() async {
    final result = state.value;
    if (result == null) return null;

    final selected = _ref.read(selectedPdfImagesProvider);
    final entries = <PdfImageEntry>[
      for (final entry in result.extractable)
        if (selected.contains(entry.objectNumber)) entry,
    ];
    if (entries.isEmpty) return const PdfSaveSummary();

    return _ref
        .read(pdfExtractionServiceProvider)
        .saveImages(entries, sourceName: _ref.read(pickedPdfNameProvider));
  }

  /// Clears everything, so leaving and returning starts on an empty screen.
  void reset() {
    state = const AsyncValue.data(null);
    _ref.read(pickedPdfNameProvider.notifier).state = '';
    _ref.read(selectedPdfImagesProvider.notifier).state = <int>{};
  }
}

final pdfExtractionControllerProvider =
    StateNotifierProvider<
      PdfExtractionController,
      AsyncValue<PdfExtractionResult?>
    >((ref) {
      return PdfExtractionController(ref);
    });

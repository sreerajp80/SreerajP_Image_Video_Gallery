import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/models/ocr/ocr_language.dart';
import 'package:in_sreerajp_imgvidgal/models/ocr/ocr_result.dart';
import 'package:in_sreerajp_imgvidgal/services/ocr/ocr_engine.dart';
import 'package:in_sreerajp_imgvidgal/services/ocr/ocr_service.dart';
import 'package:in_sreerajp_imgvidgal/services/ocr/ocr_text_cleaner.dart';

/// The on-device text reader.
final ocrEngineProvider = Provider<OcrEngine>((ref) {
  return const TesseractOcrEngine();
});

/// Tidies what the reader gives back.
final ocrTextCleanerProvider = Provider<OcrTextCleaner>((ref) {
  return const OcrTextCleaner();
});

/// Reads text out of a picture.
final ocrServiceProvider = Provider<OcrService>((ref) {
  return OcrService(
    engine: ref.watch(ocrEngineProvider),
    cleaner: ref.watch(ocrTextCleanerProvider),
  );
});

/// Which language the text screen is set to.
///
/// English by default. Both languages at once is slower and a little more
/// likely to misread a letter, so it is a choice rather than the starting
/// point.
final ocrLanguageProvider = StateProvider<OcrLanguage>((ref) {
  return OcrLanguage.english;
});

/// Reads one picture and holds the result.
class OcrController extends StateNotifier<AsyncValue<OcrResult?>> {
  final Ref _ref;

  OcrController(this._ref) : super(const AsyncValue.data(null));

  /// Reads the picture at [path] in the language currently chosen.
  ///
  /// Tesseract on a large photo takes several seconds, which is why this is
  /// started by a tap rather than by a widget building.
  Future<void> read(String path) async {
    state = const AsyncValue.loading();

    // The service never throws: every failure comes back as a result with a
    // reason on it, so the screen always has something to say.
    final result = await _ref
        .read(ocrServiceProvider)
        .readImage(path, language: _ref.read(ocrLanguageProvider));

    state = AsyncValue.data(result);
  }

  /// Clears the result, so leaving and returning starts clean.
  void reset() => state = const AsyncValue.data(null);
}

final ocrControllerProvider =
    StateNotifierProvider.autoDispose<OcrController, AsyncValue<OcrResult?>>((
      ref,
    ) {
      return OcrController(ref);
    });

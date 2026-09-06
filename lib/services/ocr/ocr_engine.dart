import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:in_sreerajp_imgvidgal/models/ocr/ocr_language.dart';

/// Something that can read text out of an image file.
///
/// An interface so the service around it can be tested without the native
/// reader, which needs a device, a real photo, and several seconds.
abstract class OcrEngine {
  /// Reads [imagePath] and returns the raw text, untidied.
  ///
  /// Throws when the reader cannot run. The service turns that into a result.
  Future<String> readText(String imagePath, OcrLanguage language);
}

/// The real reader, backed by Tesseract.
///
/// The plugin wraps Tesseract4Android, which is the maintained successor to
/// `tess-two`. It runs entirely on the device: the language data ships in the
/// app's own assets and nothing is ever downloaded. The plugin's README shows
/// a helper that fetches language files over the network; that code is not
/// used here, and must not be.
///
/// The first call unpacks the traineddata out of the assets into app-private
/// storage, because Tesseract needs a real directory to read. That happens
/// once, inside the plugin.
class TesseractOcrEngine implements OcrEngine {
  const TesseractOcrEngine();

  @override
  Future<String> readText(String imagePath, OcrLanguage language) {
    return FlutterTesseractOcr.extractText(
      imagePath,
      language: language.code,
      args: const <String, String>{
        // Keeps the spacing between words, which matters for a screenshot of
        // a table or a receipt. Without it Tesseract squeezes columns
        // together and the reading order stops making sense.
        'preserve_interword_spaces': '1',
      },
    );
  }
}

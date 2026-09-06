import 'dart:async';
import 'dart:io';

import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/ocr/ocr_language.dart';
import 'package:in_sreerajp_imgvidgal/models/ocr/ocr_result.dart';
import 'package:in_sreerajp_imgvidgal/services/ocr/ocr_engine.dart';
import 'package:in_sreerajp_imgvidgal/services/ocr/ocr_text_cleaner.dart';

/// Reads the text out of a picture.
///
/// Everything happens on the device. The picture is one the user already has,
/// the language data ships inside the app, and the text that comes out is
/// handed to the screen and nowhere else. Nothing is logged: text read out of
/// a photo can be a payslip or a prescription.
///
/// Never throws. A missing file, a reader that fails, and a reader that hangs
/// all come back as a result carrying its reason, because hard rule 5 says a
/// bad picture must not take the app down.
///
/// Vault items are not supported. They decrypt to memory only, and the reader
/// needs a file path; writing a plaintext copy out to disk so Tesseract could
/// open it would work against the vault.
class OcrService {
  final OcrEngine _engine;
  final OcrTextCleaner _cleaner;
  final Duration _timeout;
  final int _maxImageBytes;

  OcrService({
    required OcrEngine engine,
    OcrTextCleaner cleaner = const OcrTextCleaner(),
    Duration? timeout,
    int maxImageBytes = AppConstants.ocrMaxImageBytes,
  }) : _engine = engine,
       _cleaner = cleaner,
       _timeout =
           timeout ?? const Duration(seconds: AppConstants.ocrTimeoutSeconds),
       _maxImageBytes = maxImageBytes;

  /// Reads the picture at [imagePath] in [language].
  Future<OcrResult> readImage(
    String imagePath, {
    OcrLanguage language = OcrLanguage.english,
  }) async {
    if (imagePath.trim().isEmpty) {
      return OcrResult.failed(OcrFailure.unreadableImage, language: language);
    }

    final file = File(imagePath);

    try {
      if (!await file.exists()) {
        return OcrResult.failed(OcrFailure.unreadableImage, language: language);
      }

      // Checked before the reader is started, not after: Tesseract on a very
      // large photo can take a minute and hold a lot of memory while it does.
      final size = await file.length();
      if (size > _maxImageBytes) {
        return OcrResult.failed(OcrFailure.imageTooLarge, language: language);
      }
    } catch (_) {
      return OcrResult.failed(OcrFailure.unreadableImage, language: language);
    }

    final started = DateTime.now();

    try {
      final raw = await _engine.readText(imagePath, language).timeout(_timeout);
      final lines = _cleaner.cleanLines(raw);

      return OcrResult(
        text: lines.join('\n'),
        lines: lines,
        language: language,
        duration: DateTime.now().difference(started),
      );
    } on TimeoutException {
      return OcrResult.failed(OcrFailure.timedOut, language: language);
    } catch (error) {
      // A missing traineddata file is worth telling apart from a general
      // failure: it means the app was built wrong, and the message the user
      // needs is a different one.
      final text = error.toString().toLowerCase();
      final missingData =
          text.contains('traineddata') || text.contains('tessdata');

      return OcrResult.failed(
        missingData ? OcrFailure.missingLanguageData : OcrFailure.engineFailed,
        language: language,
      );
    }
  }
}

import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/pdf/pdf_extraction_result.dart';
import 'package:in_sreerajp_imgvidgal/models/pdf/pdf_image_entry.dart';
import 'package:in_sreerajp_imgvidgal/services/backup/document_picker_channel.dart';
import 'package:in_sreerajp_imgvidgal/services/media/media_store_channel.dart';
import 'package:in_sreerajp_imgvidgal/services/pdf/pdf_image_extractor.dart';

/// Where one extracted picture ended up.
class SavedPdfImage {
  /// The entry it came from.
  final PdfImageEntry entry;

  /// The path or URI it now lives at.
  final String location;

  const SavedPdfImage({required this.entry, required this.location});
}

/// What saving a batch of pictures came to.
class PdfSaveSummary {
  /// The pictures that were written.
  final List<SavedPdfImage> saved;

  /// How many could not be written.
  final int failedCount;

  /// Whether MediaStore was unavailable and a plain folder was used instead.
  final bool usedFallbackDirectory;

  const PdfSaveSummary({
    this.saved = const <SavedPdfImage>[],
    this.failedCount = 0,
    this.usedFallbackDirectory = false,
  });

  /// Whether every picture asked for was written.
  bool get allSaved => failedCount == 0;

  /// How many were written.
  int get savedCount => saved.length;
}

/// Picks a PDF, reads the pictures out of it, and saves the chosen ones.
///
/// The parsing itself is [PdfImageExtractor], which is pure. This class is the
/// part that touches the world: the system file picker, an app-private copy,
/// and MediaStore on the way out.
///
/// The picked file is copied into app-private cache to be read, and that copy
/// is deleted in a `finally`. No PDF the user pointed at is left lying inside
/// the app afterwards.
class PdfExtractionService {
  final DocumentPickerChannel _picker;
  final MediaStoreChannel _mediaStore;
  final PdfImageExtractor _extractor;

  const PdfExtractionService({
    required DocumentPickerChannel picker,
    required MediaStoreChannel mediaStore,
    PdfImageExtractor extractor = const PdfImageExtractor(),
  }) : _picker = picker,
       _mediaStore = mediaStore,
       _extractor = extractor;

  /// Asks the user for a PDF.
  ///
  /// Returns null when they backed out, which is a normal thing to do and not
  /// an error.
  Future<PickedDocument?> pickPdf() async {
    final uri = await _picker.openDocument(mimeType: 'application/pdf');
    if (uri == null) return null;

    return await _picker.documentInfo(uri) ?? PickedDocument(uri: uri);
  }

  /// Reads every picture out of the document at [uri].
  ///
  /// Never throws: a file that cannot be read comes back as a refusal the
  /// screen can explain. The app-private copy is always deleted, whether the
  /// read worked or not.
  Future<PdfExtractionResult> readImages(String uri) async {
    if (uri.isEmpty) {
      return const PdfExtractionResult.refused(PdfRefusalReason.notAPdf);
    }

    String? copyPath;
    try {
      copyPath = await _picker.copyToCache(
        uri,
        maxBytes: AppConstants.pdfExtractMaxFileBytes,
      );
      if (copyPath == null) {
        return const PdfExtractionResult.refused(PdfRefusalReason.unreadable);
      }

      final bytes = await File(copyPath).readAsBytes();
      return _extractor.extract(bytes);
    } on DocumentPickerException catch (error) {
      return PdfExtractionResult.refused(
        error.code == 'too_large'
            ? PdfRefusalReason.fileTooLarge
            : PdfRefusalReason.unreadable,
      );
    } catch (_) {
      return const PdfExtractionResult.refused(PdfRefusalReason.unreadable);
    } finally {
      if (copyPath != null) await _deleteQuietly(copyPath);
    }
  }

  /// Writes [entries] into the shared gallery.
  ///
  /// Each picture is staged app-private first and published through
  /// MediaStore, which is what lets the app add files to the user's pictures
  /// without holding a permission over the rest of their storage. Nothing is
  /// ever overwritten: a clashing name is given a new one.
  ///
  /// One picture failing does not sink the rest, in the same way a batch does
  /// not stop for one bad file.
  Future<PdfSaveSummary> saveImages(
    List<PdfImageEntry> entries, {
    String sourceName = '',
  }) async {
    final saved = <SavedPdfImage>[];
    var failed = 0;
    var usedFallback = false;

    final stem = _fileStem(sourceName);

    for (final entry in entries) {
      if (!entry.isExtractable) {
        failed++;
        continue;
      }

      File? staged;
      try {
        staged = await _stage(entry);
        final published = await _mediaStore.publishFile(
          sourcePath: staged.path,
          displayName:
              '${stem}_${entry.objectNumber}'
              '${AppConstants.pdfExtractSuffix}.${entry.format.extension}',
          mimeType: entry.format.mimeType,
          isVideo: false,
          relativeDir: AppConstants.pdfExtractDirectoryName,
        );

        if (!published.usedMediaStore) usedFallback = true;

        saved.add(
          SavedPdfImage(
            entry: entry,
            location: published.path ?? published.uri,
          ),
        );
      } catch (_) {
        failed++;
      } finally {
        // The staged copy has done its job. Leaving it would quietly double
        // what every extraction costs in storage.
        if (staged != null) await _deleteQuietly(staged.path);
      }
    }

    return PdfSaveSummary(
      saved: saved,
      failedCount: failed,
      usedFallbackDirectory: usedFallback,
    );
  }

  Future<File> _stage(PdfImageEntry entry) async {
    final directory = Directory(
      p.join(Directory.systemTemp.path, 'pdf_extract'),
    );
    await directory.create(recursive: true);

    final file = File(
      p.join(
        directory.path,
        '${DateTime.now().microsecondsSinceEpoch}_${entry.suggestedFileName}',
      ),
    );
    await file.writeAsBytes(entry.bytes ?? Uint8List(0), flush: true);
    return file;
  }

  /// A safe name stem for the saved files, taken from the PDF's own name.
  ///
  /// The name came from a file the user picked, so it is sanitised the same
  /// way an incoming transfer's name is: no separators, no leading dot, and a
  /// plain fallback when nothing usable is left.
  static String _fileStem(String sourceName) {
    final base = p.basenameWithoutExtension(sourceName).trim();
    final cleaned = base
        .replaceAll(RegExp(r'[^A-Za-z0-9 _-]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_');

    final trimmed = cleaned.replaceAll(RegExp(r'^[._]+|[._]+$'), '');
    if (trimmed.isEmpty) return 'pdf';

    return trimmed.length > 40 ? trimmed.substring(0, 40) : trimmed;
  }

  Future<void> _deleteQuietly(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // A leftover file in app-private cache is a small problem; throwing here
      // and losing the pictures that were just extracted is a large one.
    }
  }
}

import 'dart:io';
import 'dart:typed_data';

import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/core/storage/atomic_saver.dart';
import 'package:in_sreerajp_imgvidgal/services/editor/image_render_pipeline.dart';
import 'package:path/path.dart' as p;

/// Where an edited copy was written.
class SaveOutcome {
  /// Full path of the new file.
  final String path;

  /// Size of the new file in bytes.
  final int sizeBytes;

  const SaveOutcome({required this.path, required this.sizeBytes});
}

/// Thrown when an edited copy cannot be written.
class EditorSaveException implements Exception {
  final String message;

  const EditorSaveException(this.message);

  @override
  String toString() => 'EditorSaveException: $message';
}

/// Writes the edited photo out as a new file, never over the original.
///
/// This is where the non-destructive promise is actually kept. The original
/// path is only ever read, never opened for writing and never deleted. The
/// copy goes next to it under a versioned name, written through
/// [AtomicSaver] so a failure part way through leaves nothing behind.
class EditorSaveService {
  const EditorSaveService();

  /// Builds the name of the next unused copy for [sourcePath].
  ///
  /// `IMG_0001.jpg` becomes `IMG_0001_edit1.jpg`, then `_edit2`, and so on.
  /// [exists] decides whether a candidate name is taken; it is a parameter so
  /// the naming rule can be tested without writing files.
  String buildOutputPath({
    required String sourcePath,
    required RenderFormat format,
    required bool Function(String path) exists,
  }) {
    final directory = p.dirname(sourcePath);
    final baseName = p.basenameWithoutExtension(sourcePath);
    final extension = format.extension;

    for (
      var version = 1;
      version <= AppConstants.editorMaxVersionAttempts;
      version++
    ) {
      final candidate = p.join(
        directory,
        '$baseName${AppConstants.editorOutputSuffix}$version.$extension',
      );
      if (!exists(candidate)) return candidate;
    }

    // Every version number is taken, which realistically means something is
    // wrong rather than that the user made a thousand edits.
    throw const EditorSaveException(
      'Could not find an unused name for the edited copy',
    );
  }

  /// Writes [bytes] beside [sourcePath] under a fresh versioned name.
  ///
  /// Returns where the copy landed. Any failure leaves the original photo
  /// exactly as it was.
  Future<SaveOutcome> saveCopy({
    required String sourcePath,
    required Uint8List bytes,
    required RenderFormat format,
  }) async {
    if (bytes.isEmpty) {
      throw const EditorSaveException('There is nothing to save');
    }

    final targetPath = buildOutputPath(
      sourcePath: sourcePath,
      format: format,
      exists: (path) => File(path).existsSync(),
    );

    // Guard against ever pointing at the original, however the name was
    // built. Overwriting the user's photo is the one thing that must not
    // happen here.
    if (p.equals(targetPath, sourcePath)) {
      throw const EditorSaveException(
        'The edited copy would overwrite the original',
      );
    }

    try {
      final file = await AtomicSaver.writeBytes(targetPath, bytes);
      return SaveOutcome(path: file.path, sizeBytes: bytes.length);
    } on EditorSaveException {
      rethrow;
    } catch (error) {
      throw EditorSaveException('The edited copy could not be saved: $error');
    }
  }

  /// Whether a file of [sizeBytes] is small enough for the editor to open.
  ///
  /// Editing decodes the whole photo into memory, so a very large file is
  /// refused with a message rather than risking the app being killed.
  bool isEditableSize(int sizeBytes) =>
      sizeBytes > 0 && sizeBytes <= AppConstants.editorMaxSourceBytes;
}

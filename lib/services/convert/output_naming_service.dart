import 'dart:io';
import 'dart:typed_data';

import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/core/storage/atomic_saver.dart';
import 'package:path/path.dart' as p;

/// Thrown when an output file cannot be named or written.
class OutputSaveException implements Exception {
  final String message;

  const OutputSaveException(this.message);

  @override
  String toString() => 'OutputSaveException: $message';
}

/// Names and writes every file Phase 7 produces.
///
/// This is where the non-destructive promise is kept for conversions,
/// resizes, PDFs, frames, GIFs, and trims alike. The source path is only
/// ever read. The result goes beside it under a name that is not yet taken,
/// written through [AtomicSaver] so a failure part way through leaves
/// nothing half-written behind.
class OutputNamingService {
  const OutputNamingService();

  /// Builds the next unused `<name><suffix><n>.<extension>` beside [sourcePath].
  ///
  /// `IMG_0001.jpg` with suffix `_conv` becomes `IMG_0001_conv1.webp`, then
  /// `_conv2`, and so on. [exists] decides whether a candidate is taken; it
  /// is a parameter so the naming rule can be tested without writing files.
  String buildOutputPath({
    required String sourcePath,
    required String suffix,
    required String extension,
    required bool Function(String path) exists,
  }) {
    if (sourcePath.isEmpty) {
      throw const OutputSaveException('There is no source file to name after');
    }

    final directory = p.dirname(sourcePath);
    final baseName = p.basenameWithoutExtension(sourcePath);
    final cleanExtension = extension.startsWith('.')
        ? extension.substring(1)
        : extension;

    for (
      var version = 1;
      version <= AppConstants.convertMaxVersionAttempts;
      version++
    ) {
      final candidate = p.join(
        directory,
        '$baseName$suffix$version.$cleanExtension',
      );
      if (!exists(candidate)) return candidate;
    }

    // Every version number is taken, which realistically means something is
    // wrong rather than that the user made a thousand copies.
    throw const OutputSaveException(
      'Could not find an unused name for the new file',
    );
  }

  /// Writes [bytes] beside [sourcePath] under a fresh name.
  ///
  /// Returns the file that was written. Any failure leaves the original
  /// exactly as it was.
  Future<File> saveBytes({
    required String sourcePath,
    required String suffix,
    required String extension,
    required Uint8List bytes,
  }) async {
    if (bytes.isEmpty) {
      throw const OutputSaveException('There is nothing to save');
    }

    final targetPath = reserveOutputPath(
      sourcePath: sourcePath,
      suffix: suffix,
      extension: extension,
    );

    try {
      return await AtomicSaver.writeBytes(targetPath, bytes);
    } on OutputSaveException {
      rethrow;
    } catch (error) {
      throw OutputSaveException('The file could not be saved: $error');
    }
  }

  /// Picks a free path beside [sourcePath] without writing to it yet.
  ///
  /// Used by the video trim, where Android writes the file itself and only
  /// needs to be told where it should go.
  String reserveOutputPath({
    required String sourcePath,
    required String suffix,
    required String extension,
  }) {
    final targetPath = buildOutputPath(
      sourcePath: sourcePath,
      suffix: suffix,
      extension: extension,
      exists: (path) => File(path).existsSync(),
    );

    // Guard against ever pointing at the source, however the name was built.
    // Overwriting the user's own file is the one thing that must not happen.
    if (p.equals(targetPath, sourcePath)) {
      throw const OutputSaveException(
        'The new file would overwrite the original',
      );
    }

    return targetPath;
  }

  /// Whether a file of [sizeBytes] is small enough for the converter to open.
  ///
  /// Converting decodes the whole picture into memory, so a very large file
  /// is refused with a message rather than risking the app being killed.
  bool isConvertibleSize(int sizeBytes) =>
      sizeBytes > 0 && sizeBytes <= AppConstants.convertMaxSourceBytes;
}

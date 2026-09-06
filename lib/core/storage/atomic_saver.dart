import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:in_sreerajp_imgvidgal/core/errors/app_exception.dart';
import 'package:path/path.dart' as p;

/// Utility for safe, atomic, non-destructive file operations.
///
/// Ensures files are written first to a staging `.tmp` file, validated for integrity,
/// and then swapped into place. If anything fails, the staging file is purged,
/// leaving existing target files unharmed.
class AtomicSaver {
  const AtomicSaver();

  /// Writes [bytes] atomically to [targetPath].
  ///
  /// Staging occurs at `<targetPath>.tmp_<timestamp>` before atomic rename.
  /// If [createParentDirs] is true, missing parent directories are created.
  static Future<File> writeBytes(
    String targetPath,
    Uint8List bytes, {
    bool createParentDirs = true,
  }) async {
    final targetFile = File(targetPath);
    final parentDir = targetFile.parent;

    if (createParentDirs && !await parentDir.exists()) {
      await parentDir.create(recursive: true);
    }

    final tempFileName =
        '${p.basename(targetPath)}.tmp_${DateTime.now().microsecondsSinceEpoch}';
    final tempFile = File(p.join(parentDir.path, tempFileName));

    try {
      // 1. Write staging file
      await tempFile.writeAsBytes(bytes, flush: true);

      // 2. Validate staged file
      final exists = await tempFile.exists();
      if (!exists) {
        throw AtomicSaveException(
          'Staged temporary file was not found after write',
          targetPath: targetPath,
        );
      }

      final stagedLength = await tempFile.length();
      if (stagedLength != bytes.length) {
        throw AtomicSaveException(
          'Staged file size mismatch. Expected ${bytes.length} bytes, got $stagedLength bytes',
          targetPath: targetPath,
        );
      }

      // 3. Atomically replace target
      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      final renamedFile = await tempFile.rename(targetFile.path);
      return renamedFile;
    } catch (e, st) {
      // Clean up orphaned temp file on failure
      if (await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }

      if (e is AtomicSaveException) {
        rethrow;
      }
      throw AtomicSaveException(
        'Failed to atomically save file: $e',
        targetPath: targetPath,
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Writes string [content] atomically to [targetPath], encoded as UTF-8.
  ///
  /// UTF-8, not `codeUnits`. `String.codeUnits` hands back UTF-16 units, and
  /// packing those into a byte list throws away everything above 255 — every
  /// Malayalam character in the app would be silently destroyed on the way to
  /// disk. The corruption would only show up on the next read.
  static Future<File> writeString(
    String targetPath,
    String content, {
    bool createParentDirs = true,
  }) async {
    final bytes = Uint8List.fromList(utf8.encode(content));
    return writeBytes(targetPath, bytes, createParentDirs: createParentDirs);
  }

  /// Atomically copies [sourcePath] to [destinationPath] using a temporary staging file.
  static Future<File> copyAtomic(
    String sourcePath,
    String destinationPath, {
    bool createParentDirs = true,
  }) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw AtomicSaveException(
        'Source file does not exist: $sourcePath',
        targetPath: destinationPath,
      );
    }

    final bytes = await sourceFile.readAsBytes();
    return writeBytes(
      destinationPath,
      bytes,
      createParentDirs: createParentDirs,
    );
  }

  /// Safely deletes a file if it exists without throwing if the file is already absent.
  static Future<bool> safeDelete(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}

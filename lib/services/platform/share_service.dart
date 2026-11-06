import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:in_sreerajp_imgvidgal/core/logging/app_logger.dart';

/// Service providing offline media sharing via Android's native ACTION_SEND sheet.
class ShareService {
  static const MethodChannel _channel = MethodChannel(
    'in.sreerajp.imgvidgal/intents',
  );

  /// The cache sub-folder every shared file is written to.
  ///
  /// The Android file provider (`res/xml/provider_paths.xml`) exposes only
  /// this folder, and the Kotlin `shareFile` handler refuses any other path.
  static const String shareFolderName = 'shared_media';

  /// Returns the cache folder. Replaced in tests.
  final Future<Directory> Function() _cacheDirectory;

  const ShareService({
    Future<Directory> Function() cacheDirectory = getTemporaryDirectory,
  }) : _cacheDirectory = cacheDirectory;

  /// Shares an existing file on disk through the system share sheet.
  ///
  /// The file must be inside [shareFolderName]; Android refuses anything else.
  Future<bool> shareFile({
    required String filePath,
    required String mimeType,
    String title = 'Share Media',
  }) async {
    try {
      final success = await _channel.invokeMethod<bool>('shareFile', {
        'filePath': filePath,
        'mimeType': mimeType,
        'title': title,
      });
      return success ?? false;
    } catch (error) {
      AppLogger.warning('Opening the share sheet failed', error: error);
      return false;
    }
  }

  /// Writes [bytes] to a file in the share folder and shares it.
  ///
  /// Only the last part of [filename] is used, so a name such as `../x.jpg`
  /// cannot place the file outside the share folder.
  Future<bool> shareBytes({
    required Uint8List bytes,
    required String filename,
    required String mimeType,
    String title = 'Share Media',
  }) async {
    try {
      final file = await writeShareFile(bytes: bytes, filename: filename);
      if (file == null) return false;

      return await shareFile(
        filePath: file.path,
        mimeType: mimeType,
        title: title,
      );
    } catch (error) {
      AppLogger.warning('Preparing a file to share failed', error: error);
      return false;
    }
  }

  /// Writes [bytes] into the share folder and returns the file, or null when
  /// [filename] has no usable name part.
  Future<File?> writeShareFile({
    required Uint8List bytes,
    required String filename,
  }) async {
    final safeName = p.basename(filename.replaceAll('\\', '/'));
    if (safeName.isEmpty || safeName == '.' || safeName == '..') return null;

    final cacheDir = await _cacheDirectory();
    final shareDir = Directory(p.join(cacheDir.path, shareFolderName));
    if (!shareDir.existsSync()) {
      shareDir.createSync(recursive: true);
    }

    final file = File(p.join(shareDir.path, safeName));
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}

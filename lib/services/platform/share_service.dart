import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Service providing offline media sharing via Android's native ACTION_SEND sheet.
class ShareService {
  static const MethodChannel _channel = MethodChannel(
    'in.sreerajp.imgvidgal/intents',
  );

  const ShareService();

  /// Shares an existing file on disk through the system share sheet.
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
    } catch (_) {
      return false;
    }
  }

  /// Writes [bytes] to a temporary file in the cache directory and shares it.
  Future<bool> shareBytes({
    required Uint8List bytes,
    required String filename,
    required String mimeType,
    String title = 'Share Media',
  }) async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final shareDir = Directory(p.join(cacheDir.path, 'shared_media'));
      if (!shareDir.existsSync()) {
        shareDir.createSync(recursive: true);
      }

      final file = File(p.join(shareDir.path, filename));
      await file.writeAsBytes(bytes, flush: true);

      return await shareFile(
        filePath: file.path,
        mimeType: mimeType,
        title: title,
      );
    } catch (_) {
      return false;
    }
  }
}

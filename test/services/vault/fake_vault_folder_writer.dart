import 'dart:io';

import 'package:in_sreerajp_imgvidgal/services/vault/vault_export_service.dart';

/// One call the fake folder writer received.
class FolderWrite {
  final String folderUri;
  final String displayName;
  final String mimeType;
  final String sourcePath;

  /// The source file's bytes at the moment of the call.
  final List<int> bytes;

  const FolderWrite({
    required this.folderUri,
    required this.displayName,
    required this.mimeType,
    required this.sourcePath,
    required this.bytes,
  });
}

/// A [VaultFolderWriter] that records what it was asked to write.
///
/// It reads the source while it still exists, so a test can check both what
/// was written and that the working file was shredded afterwards.
class FakeVaultFolderWriter implements VaultFolderWriter {
  final List<FolderWrite> writes = <FolderWrite>[];

  /// Whether [write] should throw, as a full or refused folder would.
  bool fail = false;

  @override
  Future<void> write({
    required String folderUri,
    required String displayName,
    required String mimeType,
    required String sourcePath,
  }) async {
    if (fail) throw const FileSystemException('The folder refused the file');
    writes.add(
      FolderWrite(
        folderUri: folderUri,
        displayName: displayName,
        mimeType: mimeType,
        sourcePath: sourcePath,
        bytes: await File(sourcePath).readAsBytes(),
      ),
    );
  }
}

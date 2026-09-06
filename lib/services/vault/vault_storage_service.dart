import 'dart:io';

import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/core/errors/app_exception.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_naming_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Owns the directory the vault's encrypted payloads live in.
///
/// The directory sits inside the app's own support directory, which no other
/// app can read and which the Android media scanner does not index. A
/// `.nomedia` marker goes in beside the payloads as a second line: even if a
/// file manager with broad access walks the tree, it is told there is no media
/// here to show.
class VaultStorageService {
  /// Overrides the app support directory. Tests point this at a temp folder;
  /// nothing else should set it.
  final Directory? _rootOverride;

  Directory? _vaultDirectory;

  VaultStorageService({Directory? rootOverride}) : _rootOverride = rootOverride;

  /// The vault directory, creating it and its `.nomedia` marker on first use.
  Future<Directory> vaultDirectory() async {
    final cached = _vaultDirectory;
    if (cached != null) return cached;

    try {
      final root = _rootOverride ?? await getApplicationSupportDirectory();
      final directory = Directory(
        p.join(root.path, AppConstants.vaultStorageDirectoryName),
      );
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final marker = File(
        p.join(directory.path, AppConstants.vaultNoMediaFileName),
      );
      if (!await marker.exists()) {
        await marker.create();
      }

      _vaultDirectory = directory;
      return directory;
    } catch (error, stackTrace) {
      throw VaultException(
        'The secure vault storage could not be opened',
        code: 'vault_dir_failed',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// The full path of [fileName] inside the vault directory.
  Future<String> pathFor(String fileName) async {
    final directory = await vaultDirectory();
    return p.join(directory.path, fileName);
  }

  /// Whether [fileName] exists inside the vault directory.
  Future<bool> exists(String fileName) async {
    return File(await pathFor(fileName)).exists();
  }

  /// Size of [fileName] in bytes, or zero when it is not there.
  Future<int> sizeOf(String fileName) async {
    final file = File(await pathFor(fileName));
    if (!await file.exists()) return 0;
    return file.length();
  }

  /// Every decrypted working file currently sitting in the vault directory.
  ///
  /// There should never be any: one is only written while a video is playing
  /// and is shredded when the player closes. Any that turn up were left by a
  /// crash or a kill, and the sweep on vault open shreds them.
  Future<List<String>> findWorkingFiles() async {
    final directory = await vaultDirectory();
    final found = <String>[];
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is File && VaultNamingService.isWorkingFile(entity.path)) {
        found.add(entity.path);
      }
    }
    return found;
  }

  /// Encrypted payloads on disk that no database row points at.
  ///
  /// [knownNames] is every file name the vault table knows about. Anything
  /// else is a leftover from an import that failed after writing its payload
  /// but before inserting its row, and is dead weight the user cannot see or
  /// reach.
  Future<List<String>> findOrphanPayloads(Set<String> knownNames) async {
    final directory = await vaultDirectory();
    final orphans = <String>[];
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File) continue;
      final name = p.basename(entity.path);
      if (!VaultNamingService.isEncryptedFile(name)) continue;
      if (knownNames.contains(name)) continue;
      orphans.add(entity.path);
    }
    return orphans;
  }
}

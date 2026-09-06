import 'dart:math';

import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';

/// Names files inside the vault directory.
///
/// The names carry nothing. Not the original file name, not the date, not the
/// type — just random hex and a fixed extension. A directory listing of the
/// vault is the one thing an attacker gets for free even without the key, so
/// it is made to say nothing at all: `3f9c...a1.enc` and no more.
///
/// Pure, so the shape and the spread of the names are unit tested without
/// touching a disk.
class VaultNamingService {
  final Random _random;

  /// Builds the service.
  ///
  /// [random] defaults to [Random.secure]. Tests pass a seeded [Random];
  /// nothing else should, because a predictable name is a predictable file.
  VaultNamingService({Random? random}) : _random = random ?? Random.secure();

  /// A fresh name for an encrypted media payload.
  String newPayloadName() =>
      '${_randomHex()}${AppConstants.vaultPayloadExtension}';

  /// A fresh name for an encrypted preview.
  String newThumbnailName() =>
      '${_randomHex()}${AppConstants.vaultThumbnailExtension}';

  /// The working file name a decrypted video is played from.
  ///
  /// Derived from the payload name rather than random, so the sweep can find
  /// and shred one even if the app died before it could be cleaned up.
  String workingNameFor(String payloadName) {
    final stem = payloadName.endsWith(AppConstants.vaultPayloadExtension)
        ? payloadName.substring(
            0,
            payloadName.length - AppConstants.vaultPayloadExtension.length,
          )
        : payloadName;
    return '$stem${AppConstants.vaultWorkingExtension}';
  }

  /// Whether [fileName] is a decrypted working file.
  static bool isWorkingFile(String fileName) =>
      fileName.endsWith(AppConstants.vaultWorkingExtension);

  /// Whether [fileName] is an encrypted payload or preview.
  static bool isEncryptedFile(String fileName) =>
      fileName.endsWith(AppConstants.vaultPayloadExtension) ||
      fileName.endsWith(AppConstants.vaultThumbnailExtension);

  /// Lower-case hex over [AppConstants.vaultPayloadNameBytes] random bytes.
  String _randomHex() {
    final buffer = StringBuffer();
    for (var i = 0; i < AppConstants.vaultPayloadNameBytes; i++) {
      buffer.write(_random.nextInt(256).toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }
}

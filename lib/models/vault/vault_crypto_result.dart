import 'package:flutter/foundation.dart';

/// Immutable result of encrypting one file into the vault.
///
/// The key is never part of this: it stays inside the Android Keystore and no
/// byte of it ever crosses the channel. What comes back is only what has to be
/// stored beside the ciphertext to read it again.
@immutable
class VaultCryptoResult {
  /// Name the ciphertext was written under, inside the vault directory.
  final String fileName;

  /// Base64 of the random 96-bit initialisation vector this file used.
  ///
  /// A fresh one per file, which is what makes it safe to encrypt many files
  /// under one key.
  final String iv;

  /// Size of the ciphertext on disk, in bytes.
  ///
  /// Larger than the original by the length of the authentication tag.
  final int cipherSizeBytes;

  const VaultCryptoResult({
    required this.fileName,
    required this.iv,
    required this.cipherSizeBytes,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VaultCryptoResult &&
          runtimeType == other.runtimeType &&
          fileName == other.fileName &&
          iv == other.iv &&
          cipherSizeBytes == other.cipherSizeBytes;

  @override
  int get hashCode => Object.hash(fileName, iv, cipherSizeBytes);
}

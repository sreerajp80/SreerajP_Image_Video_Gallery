import 'package:flutter/foundation.dart';
import 'package:in_sreerajp_imgvidgal/models/vault/vault_payload_digest.dart';

/// Immutable result of encrypting one file into the vault.
///
/// The key is never part of this: no byte of the master key or the data
/// keyset ever crosses the channel. What comes back is only what has to be
/// stored beside the ciphertext to read it again.
@immutable
class VaultCryptoResult {
  /// Name the ciphertext was written under, inside the vault directory.
  final String fileName;

  /// Base64 of the per-file value needed to read the payload again.
  ///
  /// Format 1: the random 96-bit AES-GCM IV. Format 2: a random 128-bit file
  /// id, bound to the ciphertext as associated data, so a payload swapped
  /// for another one on disk fails its check. Fresh per file either way.
  final String iv;

  /// Size of the ciphertext on disk, in bytes.
  ///
  /// Larger than the original by the length of the authentication tag.
  final int cipherSizeBytes;

  /// Which payload format was written: one of
  /// `AppConstants.vaultPayloadFormat*`. Stored in the row, so the reader
  /// knows how to open it.
  final int format;

  /// What the plaintext measured while it was being encrypted, for the
  /// read-back check (`VaultCryptoService.verifyWritten`).
  final VaultPayloadDigest plain;

  const VaultCryptoResult({
    required this.fileName,
    required this.iv,
    required this.cipherSizeBytes,
    required this.format,
    required this.plain,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VaultCryptoResult &&
          runtimeType == other.runtimeType &&
          fileName == other.fileName &&
          iv == other.iv &&
          cipherSizeBytes == other.cipherSizeBytes &&
          format == other.format &&
          plain == other.plain;

  @override
  int get hashCode => Object.hash(fileName, iv, cipherSizeBytes, format, plain);
}

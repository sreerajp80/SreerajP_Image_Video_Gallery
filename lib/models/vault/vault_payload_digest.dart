import 'package:flutter/foundation.dart';

/// What a payload decrypts to, measured without the plaintext itself.
///
/// The read-back check compares this with what was measured while the file
/// was being encrypted. It is held only for that moment: never stored, never
/// logged.
@immutable
class VaultPayloadDigest {
  /// Lower-case hex SHA-256 of the plaintext.
  final String sha256;

  /// Length of the plaintext in bytes.
  final int plainBytes;

  const VaultPayloadDigest({required this.sha256, required this.plainBytes});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VaultPayloadDigest &&
          runtimeType == other.runtimeType &&
          sha256 == other.sha256 &&
          plainBytes == other.plainBytes;

  @override
  int get hashCode => Object.hash(sha256, plainBytes);

  // A digest of private content is not printed, even in a debug log.
  @override
  String toString() => 'VaultPayloadDigest($plainBytes bytes)';
}

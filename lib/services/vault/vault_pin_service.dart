import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';

/// Turns a PIN into stored bytes, and checks one against them.
///
/// The PIN itself is never stored anywhere. What is stored is a random salt
/// and the PBKDF2-HMAC-SHA256 output over the PIN and that salt, so someone
/// who reads the store still has to run the derivation once per guess. The
/// salt is per-vault, so two people with the same PIN store different bytes.
///
/// Everything here is pure: bytes in, bytes out, no files and no platform. It
/// is written over the `crypto` package the app already had rather than
/// pulling in a key-derivation package, and every step is unit tested.
class VaultPinService {
  final Random _random;

  /// Builds the service.
  ///
  /// [random] defaults to [Random.secure]. Tests pass a seeded [Random] to get
  /// repeatable salts; nothing else should.
  VaultPinService({Random? random}) : _random = random ?? Random.secure();

  /// A fresh random salt, base64 encoded.
  String generateSalt() {
    final bytes = Uint8List(AppConstants.vaultPinSaltBytes);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = _random.nextInt(256);
    }
    return base64Encode(bytes);
  }

  /// Derives the stored hash for [pin] under [saltBase64], base64 encoded.
  ///
  /// [iterations] is stored beside the hash so the count can be raised later
  /// without stranding vaults created under the old one.
  String hashPin(
    String pin,
    String saltBase64, {
    int iterations = AppConstants.vaultPinIterations,
  }) {
    final salt = base64Decode(saltBase64);
    final derived = pbkdf2(
      password: utf8.encode(pin),
      salt: salt,
      iterations: iterations,
      keyLength: AppConstants.vaultPinHashBytes,
    );
    return base64Encode(derived);
  }

  /// Whether [pin] derives to [expectedHashBase64] under [saltBase64].
  ///
  /// The comparison runs over every byte whatever happens, so how long a
  /// wrong PIN takes to reject says nothing about how much of it was right.
  bool verifyPin(
    String pin,
    String saltBase64,
    String expectedHashBase64, {
    int iterations = AppConstants.vaultPinIterations,
  }) {
    if (pin.isEmpty || saltBase64.isEmpty || expectedHashBase64.isEmpty) {
      return false;
    }
    try {
      final actual = base64Decode(
        hashPin(pin, saltBase64, iterations: iterations),
      );
      final expected = base64Decode(expectedHashBase64);
      return constantTimeEquals(actual, expected);
    } on FormatException {
      // A store that has been corrupted or hand-edited. Refusing is the only
      // safe answer; it is not an unlock.
      return false;
    }
  }

  /// PBKDF2-HMAC-SHA256, as defined in RFC 8018.
  ///
  /// Kept static and public so the derivation itself can be tested against
  /// published vectors, separately from the salt and store handling.
  static Uint8List pbkdf2({
    required List<int> password,
    required List<int> salt,
    required int iterations,
    required int keyLength,
  }) {
    if (iterations < 1) {
      throw ArgumentError.value(iterations, 'iterations', 'must be at least 1');
    }
    if (keyLength < 1) {
      throw ArgumentError.value(keyLength, 'keyLength', 'must be at least 1');
    }

    final hmac = Hmac(sha256, password);
    const blockLength = 32; // SHA-256 output, in bytes.
    final blockCount = (keyLength + blockLength - 1) ~/ blockLength;
    final output = Uint8List(blockCount * blockLength);

    for (var block = 1; block <= blockCount; block++) {
      // U1 = HMAC(password, salt || INT_BE32(block))
      final seed = Uint8List(salt.length + 4)
        ..setRange(0, salt.length, salt)
        ..[salt.length] = (block >> 24) & 0xFF
        ..[salt.length + 1] = (block >> 16) & 0xFF
        ..[salt.length + 2] = (block >> 8) & 0xFF
        ..[salt.length + 3] = block & 0xFF;

      var u = Uint8List.fromList(hmac.convert(seed).bytes);
      final accumulator = Uint8List.fromList(u);

      // Un = HMAC(password, Un-1), all XORed together.
      for (var round = 1; round < iterations; round++) {
        u = Uint8List.fromList(hmac.convert(u).bytes);
        for (var i = 0; i < blockLength; i++) {
          accumulator[i] ^= u[i];
        }
      }

      output.setRange(
        (block - 1) * blockLength,
        block * blockLength,
        accumulator,
      );
    }

    return Uint8List.sublistView(output, 0, keyLength);
  }

  /// Compares two byte lists without giving away where they first differ.
  ///
  /// A plain `==` walk returns as soon as a byte differs, and the time that
  /// takes leaks how many leading bytes were right. This one always looks at
  /// everything.
  static bool constantTimeEquals(List<int> a, List<int> b) {
    // The lengths themselves are not secret, and a length mismatch means the
    // stored value is not a hash of ours at all.
    if (a.length != b.length) return false;
    var difference = 0;
    for (var i = 0; i < a.length; i++) {
      difference |= a[i] ^ b[i];
    }
    return difference == 0;
  }
}

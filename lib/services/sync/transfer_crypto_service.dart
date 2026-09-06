import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/services/backup/backup_crypto_channel.dart';

/// Encrypts what crosses the Wi-Fi, and proves each side holds the key.
///
/// A home Wi-Fi is a shared network. Another device on the same router can
/// see the port is open and can try to connect to it, so "it is only the
/// local network" is not on its own a reason to send photos in the clear.
///
/// Two things follow from that:
///
/// * **Every frame body is encrypted** under the session key from the pairing
///   code, with its own IV. Somebody watching the network sees frame sizes and
///   nothing else.
/// * **The handshake proves possession without sending the key.** Each side
///   sends a random challenge; the other returns an HMAC of it under the
///   session key. A peer that did not scan the code cannot produce that, and
///   the key itself never crosses the wire, so watching a handshake teaches
///   an eavesdropper nothing they could reuse.
///
/// The AES work happens in Kotlin on the shared `backup` channel, so every
/// cipher operation in the app lives in one of two files.
class TransferCryptoService {
  final BackupCryptoChannel _channel;

  TransferCryptoService({BackupCryptoChannel? channel})
    : _channel = channel ?? BackupCryptoChannel();

  /// Draws a fresh pairing secret for one transfer.
  ///
  /// This is what the QR code and the typed code both carry. It exists for
  /// the length of the session and is dropped when the screen closes. It is
  /// never written to disk and never logged.
  Future<Uint8List> newPairingSecret() =>
      _channel.randomBytes(AppConstants.syncPairingSecretBytes);

  /// Turns a pairing secret into the AES key the transfer uses.
  ///
  /// Both sides run this, so scanning the QR code and typing the short code
  /// end at exactly the same key. That is the whole reason the code carries a
  /// secret rather than a key: a 32-byte key cannot be read aloud, and having
  /// the typed route use a weaker key than the scanned one would make the
  /// fallback quietly worse than the default.
  ///
  /// HMAC-SHA256 under a fixed label, which is a standard way to stretch one
  /// short secret into one full-length key. The label pins the result to this
  /// use and this protocol version, so the same secret could never produce
  /// the same key for anything else.
  static Uint8List deriveSessionKey(
    Uint8List secret, {
    int protocolVersion = AppConstants.syncProtocolVersion,
  }) {
    final label = utf8.encode('imgvidgal-session-v$protocolVersion');
    final bytes = Hmac(sha256, secret).convert(label).bytes;
    return Uint8List.fromList(bytes);
  }

  /// Draws a fresh IV.
  ///
  /// A new one for every frame. Reusing an IV under one key is the single
  /// mistake that undoes AES-GCM entirely, so it is drawn per frame rather
  /// than per session and never derived from a counter the peer influences.
  Future<Uint8List> newIv() =>
      _channel.randomBytes(AppConstants.syncIvLengthBytes);

  /// Draws a random challenge for the handshake.
  Future<Uint8List> newChallenge() => _channel.randomBytes(32);

  /// Encrypts one frame body.
  ///
  /// The IV is returned alongside the ciphertext and travels with it: it is
  /// not a secret, it only has to be different every time.
  Future<({Uint8List iv, Uint8List bytes})> seal({
    required Uint8List key,
    required Uint8List plain,
    Uint8List? aad,
  }) async {
    final iv = await newIv();
    final bytes = await _channel.encryptWithKey(
      key: key,
      bytes: plain,
      iv: iv,
      aad: aad,
    );
    return (iv: iv, bytes: bytes);
  }

  /// Decrypts one frame body.
  ///
  /// Throws [BackupCryptoException] when the tag does not check out, which is
  /// how a tampered or wrongly-keyed frame is caught. The session treats that
  /// as fatal: a peer that cannot produce a valid frame is not one to keep
  /// talking to.
  Future<Uint8List> open({
    required Uint8List key,
    required Uint8List iv,
    required Uint8List bytes,
    Uint8List? aad,
  }) {
    return _channel.decryptWithKey(key: key, bytes: bytes, iv: iv, aad: aad);
  }

  /// The answer to a handshake challenge.
  ///
  /// HMAC-SHA256 over the challenge under the session key. Computed in Dart
  /// because `crypto` is already a dependency and an HMAC needs no platform
  /// help; the key still never leaves the device.
  ///
  /// The protocol version is mixed in, so an answer computed for one version
  /// cannot be replayed against another.
  static Uint8List proofFor({
    required Uint8List key,
    required Uint8List challenge,
    int protocolVersion = AppConstants.syncProtocolVersion,
  }) {
    final message = <int>[
      ...utf8.encode('imgvidgal-pair-v$protocolVersion:'),
      ...challenge,
    ];
    return Uint8List.fromList(Hmac(sha256, key).convert(message).bytes);
  }

  /// Whether [proof] is the right answer to [challenge].
  ///
  /// Compared in constant time. A comparison that returned early on the first
  /// wrong byte would leak, one byte at a time, what the right answer is —
  /// the same reason the vault's PIN check is written this way.
  static bool verifyProof({
    required Uint8List key,
    required Uint8List challenge,
    required Uint8List proof,
    int protocolVersion = AppConstants.syncProtocolVersion,
  }) {
    final expected = proofFor(
      key: key,
      challenge: challenge,
      protocolVersion: protocolVersion,
    );
    if (proof.length != expected.length) return false;

    var difference = 0;
    for (var i = 0; i < expected.length; i++) {
      difference |= expected[i] ^ proof[i];
    }
    return difference == 0;
  }

  /// SHA-256 of some bytes, lower-case hex.
  ///
  /// Used to check an arriving file against the digest its manifest entry
  /// promised, before it is allowed anywhere near the gallery.
  static String hexDigest(List<int> bytes) => sha256.convert(bytes).toString();
}

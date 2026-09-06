import 'dart:convert';

import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/pairing_payload.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/sync_role.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/local_address_rules.dart';

/// Turns a [PairingPayload] into the text a QR code carries, and back.
///
/// Pure, and strict in the decode direction. Everything this class parses
/// came off a camera pointed at an unknown screen, so a malformed string, a
/// wrong version, a bad checksum or an address that is not local all end as
/// null rather than as a half-built payload somebody then tries to connect to.
///
/// Two shapes are produced from the same payload:
///
/// * the **QR string**, compact and complete, for the camera;
/// * the **manual code**, six short groups a person can read aloud, for a
///   device with no working camera. The manual code carries only the address,
///   the port and a shortened key, so it is the weaker of the two and is
///   offered as the fallback rather than the default.
class PairingCodec {
  const PairingCodec._();

  /// Scheme prefix, so a scanner that reads some other QR code in the frame
  /// can tell at a glance it is not ours.
  static const String scheme = 'imgvidgal-pair';

  /// Field separator inside the QR string.
  static const String _sep = '|';

  /// Bytes of the pairing secret the manual code carries.
  ///
  /// All of it. The QR code and the typed code carry the same secret, and
  /// both sides derive the same AES key from it, so neither route is the
  /// weaker one.
  static const int _manualKeyBytes = AppConstants.syncPairingSecretBytes;

  /// Bytes the manual code packs: four of address, two of port, then the key
  /// prefix. Fifteen bytes is 120 bits, which is 24 base32 characters with
  /// nothing left over.
  static const int _manualPackedBytes = 6 + _manualKeyBytes;

  /// Characters the manual code is written in.
  ///
  /// Crockford-style: no `I`, `L`, `O` or `U`, so a person reading a code off
  /// a screen cannot turn a one into an el or a zero into an oh.
  static const String manualAlphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

  // ------------------------------------------------------------ QR encoding

  /// Builds the string the QR code will hold.
  ///
  /// Layout: `imgvidgal-pair|<version>|<host>|<port>|<role>|<key>|<name>|<crc>`
  ///
  /// The device name goes last but one and is base64url encoded, because it
  /// is the only free-text field and a phone called "Sam's | Pixel" must not
  /// be able to shift every field after it.
  static String encode(PairingPayload payload) {
    final body = <String>[
      scheme,
      '${payload.protocolVersion}',
      payload.host,
      '${payload.port}',
      payload.hostRole.name,
      payload.sessionKey,
      _encodeName(payload.deviceName),
    ].join(_sep);

    return '$body$_sep${_checksum(body)}';
  }

  /// Reads a scanned string, or returns null if it is not a pairing code this
  /// build can act on.
  ///
  /// Null covers every failure on purpose. There is nothing useful a caller
  /// could do with the difference between "wrong scheme" and "bad checksum",
  /// and the screen says the same thing either way: point the camera at the
  /// other phone's code.
  static PairingPayload? decode(String raw) {
    final text = raw.trim();
    if (text.isEmpty || text.length > 512) return null;

    final parts = text.split(_sep);
    if (parts.length != 8) return null;
    if (parts[0] != scheme) return null;

    // The checksum covers everything before it, so a single mistyped or
    // misread character is caught here rather than at connect time.
    final body = parts.sublist(0, 7).join(_sep);
    if (parts[7] != _checksum(body)) return null;

    final version = int.tryParse(parts[1]);
    if (version == null || version != AppConstants.syncProtocolVersion) {
      return null;
    }

    final host = parts[2];
    // The address check happens here, at the edge, as well as at the socket.
    // A pairing code for an address off the local network is not a transfer
    // this app will ever make, so it never becomes a payload at all.
    if (!LocalAddressRules.isLocal(host)) return null;

    final port = int.tryParse(parts[3]);
    if (port == null || !LocalAddressRules.isUsablePort(port)) return null;

    final role = _roleFromName(parts[4]);
    if (role == null) return null;

    final key = parts[5];
    if (!_isPlausibleKey(key)) return null;

    final name = _decodeName(parts[6]);
    if (name == null) return null;

    return PairingPayload(
      protocolVersion: version,
      host: host,
      port: port,
      sessionKey: key,
      deviceName: name,
      hostRole: role,
    );
  }

  // -------------------------------------------------------- manual encoding

  /// Builds the typed fallback code: six groups of four characters.
  ///
  /// It packs the four address octets, the port, and the first bytes of the
  /// session key. It is shorter than the QR string and therefore weaker, and
  /// the screen says so.
  static String? encodeManual(PairingPayload payload) {
    final octets = _octetsOf(payload.host);
    if (octets == null) return null;
    if (!LocalAddressRules.isUsablePort(payload.port)) return null;

    final keyBytes = _decodeKey(payload.sessionKey);
    if (keyBytes == null) return null;

    // 4 address bytes + 2 port bytes + 9 key bytes = 15 bytes = 120 bits,
    // which base32 writes as exactly 24 characters: the six groups of four
    // the manual code is defined as, with no padding character needed.
    final bytes = <int>[
      ...octets,
      (payload.port >> 8) & 0xFF,
      payload.port & 0xFF,
      ...keyBytes.take(_manualKeyBytes),
    ];

    final encoded = _toBase32(bytes);
    final groups = <String>[];
    for (
      var i = 0;
      i < encoded.length;
      i += AppConstants.syncManualCodeGroupLength
    ) {
      final end = (i + AppConstants.syncManualCodeGroupLength).clamp(
        0,
        encoded.length,
      );
      groups.add(encoded.substring(i, end));
    }
    return groups.take(AppConstants.syncManualCodeGroupCount).join('-');
  }

  /// Normalises a typed code: upper case, dashes and spaces removed, and the
  /// characters a person is likely to substitute mapped back.
  ///
  /// Separate from decoding so the text field can normalise as the user types
  /// without deciding whether the code is valid yet.
  static String normaliseManual(String raw) {
    final buffer = StringBuffer();
    for (final rune in raw.toUpperCase().runes) {
      final ch = String.fromCharCode(rune);
      if (ch == '-' || ch == ' ') continue;
      // The four characters the alphabet leaves out, folded to what the
      // person almost certainly meant.
      switch (ch) {
        case 'I':
        case 'L':
          buffer.write('1');
        case 'O':
          buffer.write('0');
        case 'U':
          buffer.write('V');
        default:
          if (manualAlphabet.contains(ch)) buffer.write(ch);
      }
    }
    return buffer.toString();
  }

  /// Reads a typed code back into an address and a port.
  ///
  /// Returns null if the code is the wrong length or holds an address the
  /// transfer feature may not talk to. The session key it carries is only a
  /// prefix, so the caller pairs on it and the full key check still happens
  /// in the handshake.
  static ({String host, int port, List<int> keyPrefix})? decodeManual(
    String raw,
  ) {
    final text = normaliseManual(raw);
    const expected =
        AppConstants.syncManualCodeGroupLength *
        AppConstants.syncManualCodeGroupCount;
    if (text.length != expected) return null;

    final bytes = _fromBase32(text);
    if (bytes == null || bytes.length < _manualPackedBytes) return null;

    final host = '${bytes[0]}.${bytes[1]}.${bytes[2]}.${bytes[3]}';
    if (!LocalAddressRules.isLocal(host)) return null;

    final port = (bytes[4] << 8) | bytes[5];
    if (!LocalAddressRules.isUsablePort(port)) return null;

    return (
      host: host,
      port: port,
      keyPrefix: bytes.sublist(6, _manualPackedBytes),
    );
  }

  // ------------------------------------------------------------------ inner

  static String _encodeName(String name) {
    // Cap it so one long name cannot push the QR code past what a phone
    // camera can read across a table.
    final clipped = name.length > 40 ? name.substring(0, 40) : name;
    return base64Url.encode(utf8.encode(clipped)).replaceAll('=', '');
  }

  static String? _decodeName(String encoded) {
    try {
      final padded = encoded.padRight((encoded.length + 3) & ~3, '=');
      return utf8.decode(base64Url.decode(padded), allowMalformed: false);
    } catch (_) {
      return null;
    }
  }

  static SyncRole? _roleFromName(String name) {
    for (final role in SyncRole.values) {
      if (role.name == name) return role;
    }
    return null;
  }

  /// Whether a key string is the right shape to be one of ours.
  ///
  /// Length and alphabet only. It cannot tell a real key from a made-up one
  /// of the right size, and does not try: that is what the handshake is for.
  static bool _isPlausibleKey(String key) {
    final bytes = _decodeKey(key);
    return bytes != null && bytes.length == AppConstants.syncPairingSecretBytes;
  }

  static List<int>? _decodeKey(String key) {
    try {
      final padded = key.padRight((key.length + 3) & ~3, '=');
      return base64Url.decode(padded);
    } catch (_) {
      return null;
    }
  }

  static List<int>? _octetsOf(String host) {
    if (!LocalAddressRules.isLocal(host)) return null;
    final parts = host.trim().split('.');
    if (parts.length != 4) return null;
    final octets = <int>[];
    for (final part in parts) {
      final value = int.tryParse(part);
      if (value == null || value < 0 || value > 255) return null;
      octets.add(value);
    }
    return octets;
  }

  /// A short, non-cryptographic checksum over the code body.
  ///
  /// It catches a misread character, which is all it is for. It is not a
  /// message authentication code and is not treated as one: an attacker who
  /// can rewrite the QR code can recompute this, and the thing that actually
  /// stops them is that they still would not know the session key.
  static String _checksum(String body) {
    var hash = 0x811C9DC5;
    for (final unit in utf8.encode(body)) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash.toRadixString(36).padLeft(7, '0').substring(0, 7);
  }

  /// Base32 over [manualAlphabet], five bits at a time.
  static String _toBase32(List<int> bytes) {
    final buffer = StringBuffer();
    var accumulator = 0;
    var bits = 0;
    for (final byte in bytes) {
      accumulator = (accumulator << 8) | byte;
      bits += 8;
      while (bits >= 5) {
        bits -= 5;
        buffer.write(manualAlphabet[(accumulator >> bits) & 0x1F]);
      }
    }
    if (bits > 0) {
      buffer.write(manualAlphabet[(accumulator << (5 - bits)) & 0x1F]);
    }
    return buffer.toString();
  }

  static List<int>? _fromBase32(String text) {
    final bytes = <int>[];
    var accumulator = 0;
    var bits = 0;
    for (final rune in text.runes) {
      final index = manualAlphabet.indexOf(String.fromCharCode(rune));
      if (index < 0) return null;
      accumulator = (accumulator << 5) | index;
      bits += 5;
      if (bits >= 8) {
        bits -= 8;
        bytes.add((accumulator >> bits) & 0xFF);
      }
    }
    return bytes;
  }
}

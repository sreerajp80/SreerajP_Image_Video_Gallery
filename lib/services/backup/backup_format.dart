import 'dart:convert';
import 'dart:typed_data';

import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';

/// Thrown when a file is not a backup archive this build can open.
class BackupFormatException implements Exception {
  final String message;
  const BackupFormatException(this.message);

  @override
  String toString() => 'BackupFormatException: $message';
}

/// The plaintext header that sits at the front of every `.gallerybak` file.
///
/// It has to be readable without the password, because it carries the salt
/// and the iteration count the password is stretched with. What it must not
/// do is let anyone *change* those: an attacker who could rewrite the
/// iteration count down to 1 would turn a strong password into a weak one.
///
/// So the header bytes are fed to AES-GCM as additional authenticated data.
/// They are not encrypted, they are *authenticated*: alter a single byte of
/// the magic, the version, the salt, the iteration count or the IV, and the
/// tag check fails and the archive will not open at all.
class BackupHeader {
  /// Container layout version.
  final int formatVersion;

  /// Random salt the password is stretched with.
  final Uint8List salt;

  /// PBKDF2 rounds used. Stored so an archive written with a different count
  /// still opens after the constant changes.
  final int iterations;

  /// AES-GCM initialisation vector for the body.
  final Uint8List iv;

  const BackupHeader({
    required this.formatVersion,
    required this.salt,
    required this.iterations,
    required this.iv,
  });

  /// Total header length in bytes for the current layout.
  ///
  /// magic(4) + version(1) + saltLen(1) + salt + iterations(4) + ivLen(1) + iv
  int get lengthBytes =>
      BackupFormat.magicBytes + 1 + 1 + salt.length + 4 + 1 + iv.length;
}

/// Reads and writes the `.gallerybak` envelope.
///
/// Pure and byte-level, so the whole container can be tested without a device,
/// a keystore or a file picker. The cipher itself lives in Kotlin; this class
/// only decides what goes around it.
///
/// Layout, all integers big-endian:
///
/// ```
///  offset  size  field
///  0       4     magic, the ASCII bytes "GBAK"
///  4       1     format version
///  5       1     salt length, in bytes
///  6       n     salt
///  6+n     4     PBKDF2 iteration count
///  10+n    1     IV length, in bytes
///  11+n    m     IV
///  11+n+m  ...   AES-256-GCM ciphertext of the gzipped JSON body,
///                with the 128-bit tag appended
/// ```
///
/// Nothing about the library is in the clear. The counts and the date live
/// inside the encrypted body, because how many photos somebody has is itself
/// worth not leaking to anyone who picks the file up.
class BackupFormat {
  const BackupFormat._();

  /// Length of the magic marker.
  static const int magicBytes = 4;

  /// The magic marker as bytes.
  static Uint8List get magic =>
      Uint8List.fromList(ascii.encode(AppConstants.backupMagic));

  /// Smallest file that could possibly be an archive.
  ///
  /// Header for the current layout, plus a GCM tag, plus at least one byte of
  /// body. Anything shorter is refused before it is parsed.
  static int get minimumFileBytes =>
      magicBytes +
      1 +
      1 +
      AppConstants.backupSaltBytes +
      4 +
      1 +
      AppConstants.syncIvLengthBytes +
      16 +
      1;

  /// Builds the header bytes for a new archive.
  static Uint8List encodeHeader(BackupHeader header) {
    if (header.salt.isEmpty || header.salt.length > 255) {
      throw const BackupFormatException('Salt length must be 1 to 255 bytes');
    }
    if (header.iv.isEmpty || header.iv.length > 255) {
      throw const BackupFormatException('IV length must be 1 to 255 bytes');
    }
    if (header.iterations <= 0) {
      throw const BackupFormatException('Iteration count must be positive');
    }
    if (header.formatVersion < 1 || header.formatVersion > 255) {
      throw const BackupFormatException('Format version must be 1 to 255');
    }

    final out = BytesBuilder(copy: true)
      ..add(magic)
      ..addByte(header.formatVersion)
      ..addByte(header.salt.length)
      ..add(header.salt);

    final iterationBytes = ByteData(4)
      ..setUint32(0, header.iterations, Endian.big);
    out
      ..add(iterationBytes.buffer.asUint8List())
      ..addByte(header.iv.length)
      ..add(header.iv);

    return out.takeBytes();
  }

  /// Reads a header off the front of [bytes].
  ///
  /// Throws [BackupFormatException] with a reason the screen can turn into
  /// "this is not a backup file" rather than returning a half-read header
  /// somebody then tries to decrypt with.
  static BackupHeader decodeHeader(Uint8List bytes) {
    if (bytes.length < magicBytes + 2) {
      throw const BackupFormatException('File is too short to be an archive');
    }

    for (var i = 0; i < magicBytes; i++) {
      if (bytes[i] != magic[i]) {
        throw const BackupFormatException(
          'File does not start with the archive marker',
        );
      }
    }

    var offset = magicBytes;
    final formatVersion = bytes[offset++];
    if (formatVersion > AppConstants.backupFormatVersion) {
      throw BackupFormatException(
        'Archive format version $formatVersion is newer than this app '
        'understands (${AppConstants.backupFormatVersion})',
      );
    }
    if (formatVersion < 1) {
      throw const BackupFormatException('Archive format version is not valid');
    }

    final saltLength = bytes[offset++];
    if (saltLength == 0) {
      throw const BackupFormatException('Archive has no salt');
    }
    if (bytes.length < offset + saltLength + 5) {
      throw const BackupFormatException('Archive header is truncated');
    }

    final salt = Uint8List.sublistView(bytes, offset, offset + saltLength);
    offset += saltLength;

    final iterations = ByteData.sublistView(
      bytes,
      offset,
      offset + 4,
    ).getUint32(0, Endian.big);
    offset += 4;
    if (iterations <= 0) {
      throw const BackupFormatException('Archive iteration count is not valid');
    }

    final ivLength = bytes[offset++];
    if (ivLength == 0) {
      throw const BackupFormatException('Archive has no initialisation vector');
    }
    if (bytes.length < offset + ivLength) {
      throw const BackupFormatException('Archive header is truncated');
    }

    final iv = Uint8List.sublistView(bytes, offset, offset + ivLength);

    return BackupHeader(
      formatVersion: formatVersion,
      salt: Uint8List.fromList(salt),
      iterations: iterations,
      iv: Uint8List.fromList(iv),
    );
  }

  /// Whether [bytes] starts with the archive marker.
  ///
  /// A cheap first look, so the picker can say "that is not a backup file"
  /// without asking for a password first.
  static bool looksLikeArchive(Uint8List bytes) {
    if (bytes.length < magicBytes) return false;
    for (var i = 0; i < magicBytes; i++) {
      if (bytes[i] != magic[i]) return false;
    }
    return true;
  }

  /// Builds the name a new archive is offered under.
  ///
  /// Dated so a folder of backups sorts and reads sensibly, and with no part
  /// of it taken from the library, the device or the user.
  static String suggestedFileName(DateTime when) {
    String two(int value) => value.toString().padLeft(2, '0');
    final stamp =
        '${when.year}${two(when.month)}${two(when.day)}'
        '_${two(when.hour)}${two(when.minute)}${two(when.second)}';
    return '${AppConstants.backupFileNamePrefix}_$stamp'
        '.${AppConstants.backupFileExtension}';
  }
}

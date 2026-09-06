import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/services/backup/backup_format.dart';

Uint8List _salt([int fill = 0xAB]) =>
    Uint8List.fromList(List<int>.filled(AppConstants.backupSaltBytes, fill));

Uint8List _iv([int fill = 0xCD]) =>
    Uint8List.fromList(List<int>.filled(AppConstants.syncIvLengthBytes, fill));

BackupHeader _header({
  int formatVersion = AppConstants.backupFormatVersion,
  Uint8List? salt,
  int iterations = AppConstants.backupKdfIterations,
  Uint8List? iv,
}) {
  return BackupHeader(
    formatVersion: formatVersion,
    salt: salt ?? _salt(),
    iterations: iterations,
    iv: iv ?? _iv(),
  );
}

void main() {
  group('BackupFormat header round trip', () {
    test('a header survives encode then decode unchanged', () {
      final original = _header();
      final decoded = BackupFormat.decodeHeader(
        BackupFormat.encodeHeader(original),
      );

      expect(decoded.formatVersion, original.formatVersion);
      expect(decoded.salt, original.salt);
      expect(decoded.iterations, original.iterations);
      expect(decoded.iv, original.iv);
    });

    test('starts with the ASCII magic marker', () {
      final bytes = BackupFormat.encodeHeader(_header());
      expect(
        ascii.decode(bytes.sublist(0, BackupFormat.magicBytes)),
        AppConstants.backupMagic,
      );
    });

    test('the encoded length matches what the header reports', () {
      final header = _header();
      expect(BackupFormat.encodeHeader(header), hasLength(header.lengthBytes));
    });

    test('carries an unusual iteration count back exactly', () {
      // Stored rather than assumed, so an archive written before the constant
      // changed still opens afterwards.
      final decoded = BackupFormat.decodeHeader(
        BackupFormat.encodeHeader(_header(iterations: 60000)),
      );
      expect(decoded.iterations, 60000);
    });

    test('handles the largest iteration count that fits in four bytes', () {
      final decoded = BackupFormat.decodeHeader(
        BackupFormat.encodeHeader(_header(iterations: 0xFFFFFFFF)),
      );
      expect(decoded.iterations, 0xFFFFFFFF);
    });

    test('decodes a header followed by a body, ignoring the body', () {
      final header = BackupFormat.encodeHeader(_header());
      final withBody = Uint8List.fromList(<int>[
        ...header,
        ...List<int>.filled(500, 0x5A),
      ]);

      final decoded = BackupFormat.decodeHeader(withBody);
      expect(decoded.salt, _salt());
      expect(decoded.iv, _iv());
    });
  });

  group('BackupFormat.encodeHeader refuses bad input', () {
    test('refuses an empty salt', () {
      expect(
        () => BackupFormat.encodeHeader(_header(salt: Uint8List(0))),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('refuses a salt that will not fit in one length byte', () {
      expect(
        () => BackupFormat.encodeHeader(_header(salt: Uint8List(256))),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('refuses an empty IV', () {
      expect(
        () => BackupFormat.encodeHeader(_header(iv: Uint8List(0))),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('refuses a non-positive iteration count', () {
      expect(
        () => BackupFormat.encodeHeader(_header(iterations: 0)),
        throwsA(isA<BackupFormatException>()),
      );
      expect(
        () => BackupFormat.encodeHeader(_header(iterations: -1)),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('refuses a format version outside one byte', () {
      expect(
        () => BackupFormat.encodeHeader(_header(formatVersion: 0)),
        throwsA(isA<BackupFormatException>()),
      );
    });
  });

  group('BackupFormat.decodeHeader refuses bad input', () {
    test('refuses a file that is far too short', () {
      expect(
        () => BackupFormat.decodeHeader(Uint8List(0)),
        throwsA(isA<BackupFormatException>()),
      );
      expect(
        () => BackupFormat.decodeHeader(Uint8List(3)),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('refuses a file that is not an archive', () {
      // A JPEG, say, picked in the file dialog by mistake.
      final jpeg = Uint8List.fromList(<int>[
        0xFF,
        0xD8,
        0xFF,
        0xE0,
        ...List<int>.filled(60, 0),
      ]);
      expect(
        () => BackupFormat.decodeHeader(jpeg),
        throwsA(
          isA<BackupFormatException>().having(
            (e) => e.message,
            'message',
            contains('marker'),
          ),
        ),
      );
    });

    test('refuses a format version newer than this build', () {
      final bytes = BackupFormat.encodeHeader(_header());
      bytes[BackupFormat.magicBytes] = AppConstants.backupFormatVersion + 1;

      expect(
        () => BackupFormat.decodeHeader(bytes),
        throwsA(
          isA<BackupFormatException>().having(
            (e) => e.message,
            'message',
            contains('newer'),
          ),
        ),
      );
    });

    test('refuses a zero format version', () {
      final bytes = BackupFormat.encodeHeader(_header());
      bytes[BackupFormat.magicBytes] = 0;
      expect(
        () => BackupFormat.decodeHeader(bytes),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('refuses a header truncated inside the salt', () {
      final bytes = BackupFormat.encodeHeader(_header());
      expect(
        () => BackupFormat.decodeHeader(bytes.sublist(0, 10)),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('refuses a header truncated inside the IV', () {
      final bytes = BackupFormat.encodeHeader(_header());
      expect(
        () => BackupFormat.decodeHeader(bytes.sublist(0, bytes.length - 4)),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('refuses a header claiming a zero-length salt', () {
      final bytes = BackupFormat.encodeHeader(_header());
      bytes[BackupFormat.magicBytes + 1] = 0;
      expect(
        () => BackupFormat.decodeHeader(bytes),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('refuses a header whose iteration count was zeroed', () {
      // The header is authenticated by the cipher, so this never happens to a
      // real archive. It is checked anyway: a parser that trusts a field
      // because something else should have checked it is a parser that stops
      // being safe the day the something else moves.
      final bytes = BackupFormat.encodeHeader(_header());
      final offset = BackupFormat.magicBytes + 2 + AppConstants.backupSaltBytes;
      for (var i = 0; i < 4; i++) {
        bytes[offset + i] = 0;
      }
      expect(
        () => BackupFormat.decodeHeader(bytes),
        throwsA(isA<BackupFormatException>()),
      );
    });
  });

  group('BackupFormat.looksLikeArchive', () {
    test('is true for our own header', () {
      expect(
        BackupFormat.looksLikeArchive(BackupFormat.encodeHeader(_header())),
        isTrue,
      );
    });

    test('is false for anything else', () {
      expect(BackupFormat.looksLikeArchive(Uint8List(0)), isFalse);
      expect(BackupFormat.looksLikeArchive(Uint8List(2)), isFalse);
      expect(
        BackupFormat.looksLikeArchive(
          Uint8List.fromList(ascii.encode('NOPE????')),
        ),
        isFalse,
      );
    });
  });

  group('BackupFormat.suggestedFileName', () {
    test('is dated, sortable, and carries the right extension', () {
      final name = BackupFormat.suggestedFileName(
        DateTime(2026, 8, 30, 20, 4, 44),
      );

      expect(name, 'gallery_backup_20260830_200444.gallerybak');
      expect(name, endsWith('.${AppConstants.backupFileExtension}'));
    });

    test('pads every field to a fixed width so names sort by date', () {
      final name = BackupFormat.suggestedFileName(
        DateTime(2026, 1, 2, 3, 4, 5),
      );
      expect(name, 'gallery_backup_20260102_030405.gallerybak');
    });

    test('says nothing about the library or the device', () {
      final name = BackupFormat.suggestedFileName(DateTime(2026, 8, 30));
      expect(name, isNot(contains('sreeraj')));
      expect(RegExp(r'^[a-z_0-9.]+$').hasMatch(name), isTrue);
    });
  });

  group('BackupFormat.minimumFileBytes', () {
    test('is larger than a header alone', () {
      expect(
        BackupFormat.minimumFileBytes,
        greaterThan(_header().lengthBytes),
        reason: 'an archive needs a GCM tag and a body too',
      );
    });
  });
}

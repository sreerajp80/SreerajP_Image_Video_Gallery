import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/core/errors/app_exception.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_crypto_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_naming_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_storage_service.dart';
import 'package:path/path.dart' as p;

import 'fake_vault_channel.dart';

void main() {
  group('VaultCryptoService', () {
    late Directory root;
    late FakeVaultChannel channel;
    late VaultStorageService storage;
    late VaultCryptoService crypto;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('vault_crypto_test');
      channel = FakeVaultChannel();
      storage = VaultStorageService(rootOverride: root);
      crypto = VaultCryptoService(
        channel: channel,
        storage: storage,
        naming: VaultNamingService(random: Random(5)),
      );
    });

    tearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });

    Future<File> writeSource(String name, List<int> bytes) async {
      final file = File(p.join(root.path, name));
      await file.writeAsBytes(bytes, flush: true);
      return file;
    }

    group('encryptToPayload', () {
      test('writes the payload inside the vault directory', () async {
        final source = await writeSource('photo.jpg', <int>[1, 2, 3, 4]);

        final result = await crypto.encryptToPayload(sourcePath: source.path);

        final payload = File(await storage.pathFor(result.fileName));
        expect(await payload.exists(), isTrue);
        expect(p.dirname(payload.path), (await storage.vaultDirectory()).path);
      });

      test('gives the payload a random name and a fresh IV', () async {
        final source = await writeSource('photo.jpg', <int>[1, 2, 3, 4]);

        final first = await crypto.encryptToPayload(sourcePath: source.path);
        final second = await crypto.encryptToPayload(sourcePath: source.path);

        expect(first.fileName, isNot(second.fileName));
        // A fresh IV per file is what makes it safe to encrypt many files
        // under the one master key.
        expect(first.iv, isNot(second.iv));
        expect(first.fileName, endsWith(AppConstants.vaultPayloadExtension));
      });

      test('leaves the original untouched', () async {
        final source = await writeSource('photo.jpg', <int>[9, 9, 9]);

        await crypto.encryptToPayload(sourcePath: source.path);

        expect(await source.exists(), isTrue);
        expect(await source.readAsBytes(), <int>[9, 9, 9]);
      });

      test('the payload on disk is not the plain bytes', () async {
        final source = await writeSource('photo.jpg', <int>[1, 2, 3, 4]);

        final result = await crypto.encryptToPayload(sourcePath: source.path);
        final onDisk = await File(
          await storage.pathFor(result.fileName),
        ).readAsBytes();

        expect(onDisk, isNot(<int>[1, 2, 3, 4]));
      });

      test('reports a channel failure as a VaultException', () async {
        final source = await writeSource('photo.jpg', <int>[1]);
        channel.failEncrypt = true;

        expect(
          () => crypto.encryptToPayload(sourcePath: source.path),
          throwsA(isA<VaultException>()),
        );
      });
    });

    group('encryptThumbnailBytes', () {
      test('takes bytes, so no plaintext preview is ever written', () async {
        final result = await crypto.encryptThumbnailBytes(
          Uint8List.fromList(<int>[7, 7, 7]),
        );

        expect(result.fileName, endsWith(AppConstants.vaultThumbnailExtension));
        // Only the encrypted preview is on disk; nothing readable was written
        // on the way there.
        final directory = await storage.vaultDirectory();
        final names = directory
            .listSync()
            .map((entity) => p.basename(entity.path))
            .toList();
        expect(names, contains(result.fileName));
        expect(names.where((name) => name.endsWith('.jpg')), isEmpty);
      });
    });

    group('decryptToMemory', () {
      test('returns exactly what was encrypted', () async {
        final source = await writeSource(
          'photo.jpg',
          List<int>.generate(256, (i) => i),
        );
        final result = await crypto.encryptToPayload(sourcePath: source.path);

        final plain = await crypto.decryptToMemory(
          fileName: result.fileName,
          iv: result.iv,
          format: result.format,
        );

        expect(plain, List<int>.generate(256, (i) => i));
      });

      test('refuses a record with no file name or no IV', () async {
        expect(
          () => crypto.decryptToMemory(fileName: '', iv: 'abc', format: 2),
          throwsA(isA<VaultException>()),
        );
        expect(
          () => crypto.decryptToMemory(fileName: 'a.enc', iv: '', format: 2),
          throwsA(isA<VaultException>()),
        );
      });

      test('reports a failed decrypt rather than returning nothing', () async {
        final source = await writeSource('photo.jpg', <int>[1, 2]);
        final result = await crypto.encryptToPayload(sourcePath: source.path);
        channel.failDecrypt = true;

        expect(
          () => crypto.decryptToMemory(
            fileName: result.fileName,
            iv: result.iv,
            format: result.format,
          ),
          throwsA(isA<VaultException>()),
        );
      });
    });

    group('decryptToWorkingFile', () {
      test('writes the working file inside the vault directory', () async {
        final source = await writeSource('clip.mp4', <int>[4, 5, 6]);
        final result = await crypto.encryptToPayload(sourcePath: source.path);

        final workingPath = await crypto.decryptToWorkingFile(
          fileName: result.fileName,
          iv: result.iv,
          format: result.format,
        );

        // Not the public cache, not the temporary directory. App-private
        // storage is the whole reason this path is acceptable at all.
        expect(p.dirname(workingPath), (await storage.vaultDirectory()).path);
        expect(await File(workingPath).readAsBytes(), <int>[4, 5, 6]);
      });

      test('names the working file after its payload', () async {
        final source = await writeSource('clip.mp4', <int>[4, 5, 6]);
        final result = await crypto.encryptToPayload(sourcePath: source.path);

        final workingPath = await crypto.decryptToWorkingFile(
          fileName: result.fileName,
          iv: result.iv,
          format: result.format,
        );

        // Derived rather than random, so the sweep on the next unlock can find
        // one that a crash left behind.
        expect(
          VaultNamingService.isWorkingFile(p.basename(workingPath)),
          isTrue,
        );
        expect(
          p.basename(workingPath),
          VaultNamingService(random: Random(1)).workingNameFor(result.fileName),
        );
      });

      test('refuses an incomplete record', () async {
        expect(
          () => crypto.decryptToWorkingFile(fileName: '', iv: 'abc', format: 2),
          throwsA(isA<VaultException>()),
        );
      });
    });
  });

  group('VaultCryptoService formats and the data key', () {
    late Directory root;
    late FakeVaultChannel channel;
    late VaultStorageService storage;
    late VaultCryptoService crypto;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('vault_crypto_format_');
      channel = FakeVaultChannel();
      storage = VaultStorageService(rootOverride: root);
      crypto = VaultCryptoService(channel: channel, storage: storage);
    });

    tearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });

    test('every write uses the fast format', () async {
      final result = await crypto.encryptBytesToPayload(
        Uint8List.fromList(<int>[1, 2, 3]),
      );

      expect(result.format, AppConstants.vaultPayloadFormatStreaming);
      expect(result.fileName, endsWith(AppConstants.vaultPayloadExtension));
    });

    test('hands Android the keyset file inside the vault directory', () async {
      await crypto.encryptThumbnailBytes(Uint8List.fromList(<int>[1]));

      expect(channel.keysetPaths, <String>{
        await storage.pathFor(AppConstants.vaultDataKeyFileName),
      });
    });

    test('an old-format payload is read with the old format', () async {
      channel.writeFormat = AppConstants.vaultPayloadFormatLegacy;
      final result = await crypto.encryptBytesToPayload(
        Uint8List.fromList(<int>[5, 6]),
      );

      final plain = await crypto.decryptToMemory(
        fileName: result.fileName,
        iv: result.iv,
        format: AppConstants.vaultPayloadFormatLegacy,
      );
      expect(plain, <int>[5, 6]);
    });

    test('forgetDataKey reaches Android', () async {
      await crypto.forgetDataKey();

      expect(channel.forgetDataKeyCalls, 1);
    });

    test('the keyset file is never taken for an orphan payload', () async {
      final keyset = File(
        await storage.pathFor(AppConstants.vaultDataKeyFileName),
      );
      await keyset.writeAsBytes(<int>[1, 2, 3], flush: true);

      final orphans = await storage.findOrphanPayloads(<String>{});
      final working = await storage.findWorkingFiles();

      expect(orphans, isNot(contains(keyset.path)));
      expect(working, isNot(contains(keyset.path)));
    });

    group('verifyWritten', () {
      test('passes for a file that reads back the same', () async {
        final result = await crypto.encryptBytesToPayload(
          Uint8List.fromList(<int>[1, 2, 3, 4]),
        );

        await crypto.verifyWritten(result);
        expect(channel.digested, hasLength(1));
      });

      test('fails for a file that changed on disk', () async {
        channel.corruptNextWrites = 1;
        final result = await crypto.encryptBytesToPayload(
          Uint8List.fromList(<int>[1, 2, 3, 4]),
        );

        await expectLater(
          crypto.verifyWritten(result),
          throwsA(
            isA<VaultException>().having(
              (e) => e.code,
              'code',
              'verify_failed',
            ),
          ),
        );
      });

      test('fails when the file is gone', () async {
        final result = await crypto.encryptBytesToPayload(
          Uint8List.fromList(<int>[1, 2, 3, 4]),
        );
        await File(await storage.pathFor(result.fileName)).delete();

        await expectLater(
          crypto.verifyWritten(result),
          throwsA(
            isA<VaultException>().having(
              (e) => e.code,
              'code',
              'verify_failed',
            ),
          ),
        );
      });
    });
  });
}

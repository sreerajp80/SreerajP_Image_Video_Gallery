import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/vault_item.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/database_helper.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/media_dao.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/vault_dao.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_crypto_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_export_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_naming_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_shredder_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_storage_service.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'fake_vault_channel.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('VaultExportService', () {
    late Directory root;
    late Directory gallery;
    late DatabaseHelper dbHelper;
    late VaultDao vaultDao;
    late MediaDao mediaDao;
    late FakeVaultChannel channel;
    late VaultStorageService storage;
    late VaultCryptoService crypto;
    late VaultExportService service;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('vault_export_test');
      gallery = await Directory(p.join(root.path, 'DCIM')).create();

      dbHelper = DatabaseHelper(
        customPath: inMemoryDatabasePath,
        customFactory: databaseFactoryFfi,
      );
      vaultDao = VaultDao(dbHelper: dbHelper);
      mediaDao = MediaDao(dbHelper: dbHelper);

      channel = FakeVaultChannel()..nativeShredSucceeds = true;
      storage = VaultStorageService(rootOverride: root);
      crypto = VaultCryptoService(
        channel: channel,
        storage: storage,
        naming: VaultNamingService(random: Random(21)),
      );
      service = VaultExportService(
        crypto: crypto,
        storage: storage,
        shredder: VaultShredderService(channel: channel, random: Random(6)),
        vaultDao: vaultDao,
        mediaDao: mediaDao,
      );
    });

    tearDown(() async {
      await dbHelper.close();
      if (await root.exists()) await root.delete(recursive: true);
    });

    /// Encrypts some bytes into the vault and stores the record for them.
    Future<VaultItem> addVaultItem({
      String name = 'photo.jpg',
      List<int> bytes = const <int>[1, 2, 3, 4, 5],
      bool withThumbnail = true,
      String? originalDirectory,
    }) async {
      final originalPath = p.join(originalDirectory ?? gallery.path, name);
      final source = File(p.join(root.path, 'staging_$name'));
      await source.writeAsBytes(bytes, flush: true);

      final payload = await crypto.encryptToPayload(sourcePath: source.path);
      await source.delete();

      String? thumbnailName;
      if (withThumbnail) {
        thumbnailName = (await crypto.encryptThumbnailBytes(
          Uint8List.fromList(<int>[9, 9]),
        )).fileName;
      }

      final item = VaultItem(
        id: 'vault_$name',
        originalPath: originalPath,
        originalFilename: name,
        encryptedFilename: payload.fileName,
        encryptedThumbnailFilename: thumbnailName,
        mediaType: MediaType.image,
        mimeType: 'image/jpeg',
        sizeBytes: payload.cipherSizeBytes,
        iv: payload.iv,
        dateVaulted: DateTime(2026, 8, 30),
      );
      await vaultDao.insertVaultItem(item);
      return item;
    }

    group('exportItems', () {
      test('an empty batch does nothing', () async {
        final result = await service.exportItems(const <VaultItem>[]);

        expect(result.succeededCount, 0);
        expect(result.failedCount, 0);
      });

      test('writes the file back beside where it came from', () async {
        final item = await addVaultItem();

        final result = await service.exportItems(<VaultItem>[item]);

        expect(result.succeededCount, 1);
        final restored = gallery
            .listSync()
            .whereType<File>()
            .where(
              (file) => p
                  .basename(file.path)
                  .contains(AppConstants.vaultExportSuffix),
            )
            .toList();
        expect(restored, hasLength(1));
        expect(await restored.first.readAsBytes(), <int>[1, 2, 3, 4, 5]);
      });

      test('never overwrites a file already sitting there', () async {
        // The restored copy gets its own name. Silently replacing a photo the
        // user already has would be exactly the destructive behaviour the
        // project forbids.
        final item = await addVaultItem();
        final clashing = File(p.join(gallery.path, 'photo.jpg'));
        await clashing.writeAsString('do not touch me', flush: true);

        await service.exportItems(<VaultItem>[item]);

        expect(await clashing.readAsString(), 'do not touch me');
      });

      test('shreds the payload and the preview once the file is out', () async {
        final item = await addVaultItem();
        final payloadPath = await storage.pathFor(item.encryptedFilename);
        final thumbnailPath = await storage.pathFor(
          item.encryptedThumbnailFilename!,
        );

        await service.exportItems(<VaultItem>[item]);

        expect(await File(payloadPath).exists(), isFalse);
        expect(await File(thumbnailPath).exists(), isFalse);
      });

      test('drops the vault row', () async {
        final item = await addVaultItem();

        await service.exportItems(<VaultItem>[item]);

        expect(await vaultDao.getVaultItemById(item.id), isNull);
        expect(await vaultDao.getVaultItemsCount(), 0);
      });

      test('lets the gallery show the original row again', () async {
        final item = await addVaultItem();
        await mediaDao.insertMediaItem(
          MediaItem(
            id: 'media_1',
            path: item.originalPath,
            displayName: item.originalFilename,
            mediaType: MediaType.image,
            mimeType: 'image/jpeg',
            size: 5,
            dateAdded: DateTime(2026, 8, 30),
            dateModified: DateTime(2026, 8, 30),
            isVaulted: true,
          ),
        );

        await service.exportItems(<VaultItem>[item]);

        final reloaded = await mediaDao.getMediaItemById('media_1');
        expect(reloaded!.isVaulted, isFalse);
      });

      test('still succeeds when the original row is long gone', () async {
        // Normal after an import that shredded the original: there is nothing
        // left to un-hide, and the restore itself has already worked.
        final item = await addVaultItem();

        final result = await service.exportItems(<VaultItem>[item]);

        expect(result.succeededCount, 1);
      });

      test('falls back when the original folder no longer exists', () async {
        final vanished = Directory(p.join(root.path, 'gone'));
        final item = await addVaultItem(originalDirectory: vanished.path);

        final result = await service.exportItems(<VaultItem>[item]);

        // Better than failing the restore over a folder the user deleted.
        expect(result.succeededCount, 1);
      });

      test('a failed decrypt leaves the item safely in the vault', () async {
        final item = await addVaultItem();
        final payloadPath = await storage.pathFor(item.encryptedFilename);
        channel.failDecrypt = true;

        final result = await service.exportItems(<VaultItem>[item]);

        expect(result.failedCount, 1);
        // Nothing inside the vault is touched until the file is safely out.
        expect(await File(payloadPath).exists(), isTrue);
        expect(await vaultDao.getVaultItemById(item.id), isNotNull);
      });

      test('one failure does not sink the batch', () async {
        final good = await addVaultItem(name: 'good.jpg');
        final broken = await addVaultItem(name: 'broken.jpg');
        // Take the payload away under the second one.
        await File(await storage.pathFor(broken.encryptedFilename)).delete();

        final result = await service.exportItems(<VaultItem>[good, broken]);

        expect(result.succeededCount, 1);
        expect(result.failedCount, 1);
        expect(result.succeededIds, <String>[good.id]);
      });

      test('reports progress as it goes', () async {
        final first = await addVaultItem(name: 'a.jpg');
        final second = await addVaultItem(name: 'b.jpg');
        final seen = <int>[];

        await service.exportItems(<VaultItem>[
          first,
          second,
        ], onProgress: (done, total) => seen.add(done));

        expect(seen, <int>[1, 2]);
      });
    });

    group('deleteForever', () {
      test('an empty batch does nothing', () async {
        expect(
          (await service.deleteForever(const <VaultItem>[])).succeededCount,
          0,
        );
      });

      test('shreds the payload and the preview, and drops the row', () async {
        final item = await addVaultItem();
        final payloadPath = await storage.pathFor(item.encryptedFilename);
        final thumbnailPath = await storage.pathFor(
          item.encryptedThumbnailFilename!,
        );

        final result = await service.deleteForever(<VaultItem>[item]);

        expect(result.succeededCount, 1);
        expect(result.shreddedCount, 2);
        expect(await File(payloadPath).exists(), isFalse);
        expect(await File(thumbnailPath).exists(), isFalse);
        expect(await vaultDao.getVaultItemById(item.id), isNull);
      });

      test('writes nothing back into the gallery', () async {
        final item = await addVaultItem();

        await service.deleteForever(<VaultItem>[item]);

        expect(gallery.listSync(), isEmpty);
      });

      test('handles an item with no preview', () async {
        final item = await addVaultItem(withThumbnail: false);

        final result = await service.deleteForever(<VaultItem>[item]);

        expect(result.succeededCount, 1);
        expect(result.shreddedCount, 1);
      });

      test('a payload already gone still removes the row', () async {
        // The row pointing at nothing is the leftover worth clearing.
        final item = await addVaultItem();
        await File(await storage.pathFor(item.encryptedFilename)).delete();

        final result = await service.deleteForever(<VaultItem>[item]);

        expect(result.succeededCount, 1);
        expect(await vaultDao.getVaultItemById(item.id), isNull);
      });
    });
  });
}

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/errors/app_exception.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/vault_item.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/database_helper.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/media_dao.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/vault_dao.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_crypto_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_import_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_naming_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_preview_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_shredder_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_storage_service.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'fake_vault_channel.dart';

/// A preview builder that never reaches a decoder or a video channel.
///
/// The real one is exercised by the app; here what matters is only whether a
/// preview exists, so both answers can be forced.
class _FakePreviewService implements VaultPreviewService {
  Uint8List? preview;

  @override
  Future<Uint8List?> buildPreview(MediaItem item) async => preview;
}

/// A DAO whose insert always fails, so the roll-back path can be reached.
class _FailingVaultDao extends VaultDao {
  _FailingVaultDao({required super.dbHelper});

  @override
  Future<void> insertVaultItem(VaultItem item) async {
    throw const StorageException('insert refused');
  }
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('VaultImportService', () {
    late Directory root;
    late DatabaseHelper dbHelper;
    late VaultDao vaultDao;
    late MediaDao mediaDao;
    late FakeVaultChannel channel;
    late VaultStorageService storage;
    late VaultShredderService shredder;
    late _FakePreviewService preview;
    late VaultImportService service;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('vault_import_test');
      dbHelper = DatabaseHelper(
        customPath: inMemoryDatabasePath,
        customFactory: databaseFactoryFfi,
      );
      vaultDao = VaultDao(dbHelper: dbHelper);
      mediaDao = MediaDao(dbHelper: dbHelper);

      channel = FakeVaultChannel()..nativeShredSucceeds = true;
      storage = VaultStorageService(rootOverride: root);
      shredder = VaultShredderService(channel: channel, random: Random(2));
      preview = _FakePreviewService();

      service = VaultImportService(
        crypto: VaultCryptoService(
          channel: channel,
          storage: storage,
          naming: VaultNamingService(random: Random(9)),
        ),
        storage: storage,
        shredder: shredder,
        preview: preview,
        vaultDao: vaultDao,
        mediaDao: mediaDao,
        random: Random(4),
      );
    });

    tearDown(() async {
      await dbHelper.close();
      if (await root.exists()) await root.delete(recursive: true);
    });

    /// Writes a real file and inserts the media row that points at it.
    Future<MediaItem> addMedia(String name, {int byteCount = 64}) async {
      final file = File(p.join(root.path, name));
      await file.writeAsBytes(
        List<int>.generate(byteCount, (i) => i % 256),
        flush: true,
      );

      final item = MediaItem(
        id: 'media_$name',
        path: file.path,
        displayName: name,
        mediaType: MediaType.image,
        mimeType: 'image/jpeg',
        size: byteCount,
        dateAdded: DateTime(2026, 8, 30),
        dateModified: DateTime(2026, 8, 30),
        dateTaken: DateTime(2026, 8, 29),
        width: 100,
        height: 200,
      );
      await mediaDao.insertMediaItem(item);
      return item;
    }

    test('an empty batch does nothing', () async {
      final result = await service.importItems(const <MediaItem>[]);

      expect(result.succeededCount, 0);
      expect(result.failedCount, 0);
      expect(await vaultDao.getVaultItemsCount(), 0);
    });

    group('a successful import', () {
      test('writes a payload and a vault row', () async {
        final item = await addMedia('photo.jpg');

        final result = await service.importItems(<MediaItem>[item]);

        expect(result.succeededCount, 1);
        expect(result.failedCount, 0);

        final stored = await vaultDao.getVaultItemById(
          result.succeededIds.first,
        );
        expect(stored, isNotNull);
        expect(stored!.originalFilename, 'photo.jpg');
        expect(stored.originalPath, item.path);
        expect(stored.iv, isNotEmpty);
        expect(
          await File(await storage.pathFor(stored.encryptedFilename)).exists(),
          isTrue,
        );
      });

      test('marks the media row vaulted, which hides it everywhere', () async {
        final item = await addMedia('photo.jpg');

        await service.importItems(<MediaItem>[item]);

        // Every media query already excludes vaulted rows, so this single flag
        // is what removes it from the timeline, albums, search, and the
        // duplicate scan at once.
        final reloaded = await mediaDao.getMediaItemById(item.id);
        expect(reloaded!.isVaulted, isTrue);
      });

      test('carries the dates, size, and tags across', () async {
        final item = await addMedia('photo.jpg');

        final result = await service.importItems(<MediaItem>[item]);
        final stored = await vaultDao.getVaultItemById(
          result.succeededIds.first,
        );

        expect(stored!.dateTaken, item.dateTaken);
        expect(stored.width, 100);
        expect(stored.height, 200);
        expect(stored.mimeType, 'image/jpeg');
      });

      test('stores an encrypted preview when one can be made', () async {
        preview.preview = Uint8List.fromList(<int>[1, 2, 3]);
        final item = await addMedia('photo.jpg');

        final result = await service.importItems(<MediaItem>[item]);
        final stored = await vaultDao.getVaultItemById(
          result.succeededIds.first,
        );

        expect(stored!.encryptedThumbnailFilename, isNotNull);
        expect(
          await File(
            await storage.pathFor(stored.encryptedThumbnailFilename!),
          ).exists(),
          isTrue,
        );
      });

      test('imports fine when no preview could be made', () async {
        preview.preview = null;
        final item = await addMedia('photo.jpg');

        final result = await service.importItems(<MediaItem>[item]);
        final stored = await vaultDao.getVaultItemById(
          result.succeededIds.first,
        );

        // A missing thumbnail is cosmetic. Refusing the import over one would
        // be the wrong trade.
        expect(result.succeededCount, 1);
        expect(stored!.encryptedThumbnailFilename, isNull);
      });

      test('gives each record a random id, not the media id', () async {
        final item = await addMedia('photo.jpg');

        final result = await service.importItems(<MediaItem>[item]);

        // So nobody reading the vault table can tie a record back to a public
        // gallery row.
        expect(result.succeededIds.first, isNot(item.id));
        expect(result.succeededIds.first, matches(RegExp(r'^[0-9a-f]{32}$')));
      });
    });

    group('the original', () {
      test('is left alone by default', () async {
        final item = await addMedia('photo.jpg');

        final result = await service.importItems(<MediaItem>[item]);

        expect(await File(item.path).exists(), isTrue);
        expect(result.shreddedCount, 0);
      });

      test('is destroyed only when shredding is asked for', () async {
        final item = await addMedia('photo.jpg');

        final result = await service.importItems(<MediaItem>[
          item,
        ], shredOriginals: true);

        expect(await File(item.path).exists(), isFalse);
        expect(result.shreddedCount, 1);
      });
    });

    group('when something goes wrong', () {
      test('a failed encrypt leaves the original where it was', () async {
        final item = await addMedia('photo.jpg');
        channel.failEncrypt = true;

        final result = await service.importItems(<MediaItem>[
          item,
        ], shredOriginals: true);

        expect(result.failedCount, 1);
        expect(result.succeededCount, 0);
        // The original is only ever touched after everything else succeeded.
        expect(await File(item.path).exists(), isTrue);
        expect(result.shreddedCount, 0);
      });

      test('a failed import writes no vault row', () async {
        final item = await addMedia('photo.jpg');
        channel.failEncrypt = true;

        await service.importItems(<MediaItem>[item]);

        expect(await vaultDao.getVaultItemsCount(), 0);
        final reloaded = await mediaDao.getMediaItemById(item.id);
        expect(reloaded!.isVaulted, isFalse);
      });

      test('a failure after the payload leaves no orphan behind', () async {
        // The payload is written, then the row insert fails. What must not
        // survive is an encrypted file the user can neither see nor delete.
        final item = await addMedia('photo.jpg');
        final failing = VaultImportService(
          crypto: VaultCryptoService(
            channel: channel,
            storage: storage,
            naming: VaultNamingService(random: Random(9)),
          ),
          storage: storage,
          shredder: shredder,
          preview: preview,
          vaultDao: _FailingVaultDao(dbHelper: dbHelper),
          mediaDao: mediaDao,
          random: Random(4),
        );

        final result = await failing.importItems(<MediaItem>[item]);

        expect(result.failedCount, 1);
        // The original is still exactly where it was, too.
        expect(await File(item.path).exists(), isTrue);
        final directory = await storage.vaultDirectory();
        final leftovers = directory
            .listSync()
            .map((entity) => p.basename(entity.path))
            .where(VaultNamingService.isEncryptedFile)
            .toList();
        expect(leftovers, isEmpty);
      });

      test(
        'a missing file fails on its own without sinking the batch',
        () async {
          final good = await addMedia('good.jpg');
          final missing = await addMedia('gone.jpg');
          await File(missing.path).delete();

          final result = await service.importItems(<MediaItem>[good, missing]);

          // Losing all forty photos because the ninth was corrupt would be the
          // wrong trade.
          expect(result.succeededCount, 1);
          expect(result.failedCount, 1);
          expect(result.isPartial, isTrue);
        },
      );

      test(
        'a file too large for the vault is refused, not truncated',
        () async {
          final item = (await addMedia(
            'huge.jpg',
          )).copyWith(size: 8 * 1024 * 1024 * 1024);

          final result = await service.importItems(<MediaItem>[item]);

          expect(result.failedCount, 1);
          expect(await File(item.path).exists(), isTrue);
        },
      );
    });

    test('reports progress as it goes', () async {
      final first = await addMedia('a.jpg');
      final second = await addMedia('b.jpg');
      final seen = <int>[];

      await service.importItems(
        <MediaItem>[first, second],
        onProgress: (done, total) {
          expect(total, 2);
          seen.add(done);
        },
      );

      expect(seen, <int>[1, 2]);
    });
  });
}

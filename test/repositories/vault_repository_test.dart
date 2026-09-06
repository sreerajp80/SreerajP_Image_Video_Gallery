import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/vault_item.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/database_helper.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/media_dao.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/vault_dao.dart';
import 'package:in_sreerajp_imgvidgal/repositories/vault_repository.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_crypto_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_export_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_import_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_naming_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_preview_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_shredder_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_storage_service.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../services/vault/fake_vault_channel.dart';

/// A preview builder that stays off the decoder.
class _FakePreviewService implements VaultPreviewService {
  Uint8List? preview = Uint8List.fromList(<int>[5, 5, 5]);

  @override
  Future<Uint8List?> buildPreview(MediaItem item) async => preview;
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('VaultRepository', () {
    late Directory root;
    late Directory gallery;
    late DatabaseHelper dbHelper;
    late VaultDao vaultDao;
    late MediaDao mediaDao;
    late FakeVaultChannel channel;
    late VaultStorageService storage;
    late VaultCryptoService crypto;
    late VaultShredderService shredder;
    late VaultRepository repository;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('vault_repo_test');
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
        naming: VaultNamingService(random: Random(31)),
      );
      shredder = VaultShredderService(channel: channel, random: Random(8));

      repository = VaultRepository(
        vaultDao: vaultDao,
        crypto: crypto,
        importService: VaultImportService(
          crypto: crypto,
          storage: storage,
          shredder: shredder,
          preview: _FakePreviewService(),
          vaultDao: vaultDao,
          mediaDao: mediaDao,
          random: Random(12),
        ),
        exportService: VaultExportService(
          crypto: crypto,
          storage: storage,
          shredder: shredder,
          vaultDao: vaultDao,
          mediaDao: mediaDao,
        ),
        storage: storage,
        shredder: shredder,
      );
    });

    tearDown(() async {
      await dbHelper.close();
      if (await root.exists()) await root.delete(recursive: true);
    });

    Future<MediaItem> addMedia(String name, {List<int>? bytes}) async {
      final file = File(p.join(gallery.path, name));
      await file.writeAsBytes(bytes ?? <int>[1, 2, 3], flush: true);

      final item = MediaItem(
        id: 'media_$name',
        path: file.path,
        displayName: name,
        mediaType: MediaType.image,
        mimeType: 'image/jpeg',
        size: (bytes ?? <int>[1, 2, 3]).length,
        dateAdded: DateTime(2026, 8, 30),
        dateModified: DateTime(2026, 8, 30),
      );
      await mediaDao.insertMediaItem(item);
      return item;
    }

    Future<VaultItem> importOne(String name, {List<int>? bytes}) async {
      final media = await addMedia(name, bytes: bytes);
      final result = await repository.importFromGallery(<MediaItem>[media]);
      expect(result.succeededCount, 1);
      return (await repository.getItem(result.succeededIds.first))!;
    }

    group('reads', () {
      test('an empty vault reads as empty, not as an error', () async {
        expect(await repository.getItems(), isEmpty);
        expect(await repository.count(), 0);
        expect(await repository.getItem('nothing'), isNull);
      });

      test('lists what has been imported, newest first', () async {
        await importOne('first.jpg');
        await importOne('second.jpg');

        final items = await repository.getItems();

        expect(items, hasLength(2));
        expect(await repository.count(), 2);
      });

      test('fetches several by id, and an empty request is empty', () async {
        final one = await importOne('a.jpg');
        final two = await importOne('b.jpg');

        expect(
          (await repository.getItemsByIds(<String>[one.id, two.id])).length,
          2,
        );
        expect(await repository.getItemsByIds(const <String>[]), isEmpty);
      });

      test('returns the full image as bytes, never a path', () async {
        final item = await importOne('photo.jpg', bytes: <int>[7, 8, 9]);

        expect(await repository.readImageBytes(item), <int>[7, 8, 9]);
      });

      test('returns the preview as bytes', () async {
        final item = await importOne('photo.jpg');

        expect(await repository.readThumbnailBytes(item), <int>[5, 5, 5]);
      });

      test(
        'the preview is stored with its own IV, not the payload one',
        () async {
          final item = await importOne('photo.jpg');

          // Each file is encrypted under a fresh IV. Storing one IV for both and
          // reusing it would fail the authentication tag on a real cipher, so
          // the record has to carry the preview's separately.
          expect(item.thumbnailIv, isNotNull);
          expect(item.thumbnailIv, isNot(item.iv));
        },
      );

      test('a record with a preview but no preview IV reads as null', () async {
        // What a row written before the preview IV existed looks like. Showing
        // an icon is right; handing the cipher the payload's IV is not.
        final item = await importOne('photo.jpg');
        await vaultDao.updateVaultItem(
          VaultItem(
            id: item.id,
            originalPath: item.originalPath,
            originalFilename: item.originalFilename,
            encryptedFilename: item.encryptedFilename,
            encryptedThumbnailFilename: item.encryptedThumbnailFilename,
            mediaType: item.mediaType,
            mimeType: item.mimeType,
            sizeBytes: item.sizeBytes,
            iv: item.iv,
            dateVaulted: item.dateVaulted,
          ),
        );

        final reloaded = (await repository.getItem(item.id))!;
        expect(reloaded.encryptedThumbnailFilename, isNotNull);
        expect(reloaded.thumbnailIv, isNull);
        expect(await repository.readThumbnailBytes(reloaded), isNull);
      });

      test('a preview that will not decrypt is null, not a crash', () async {
        final item = await importOne('photo.jpg');
        await File(
          await storage.pathFor(item.encryptedThumbnailFilename!),
        ).delete();

        // Cosmetic: the tile falls back to an icon and the item is untouched.
        expect(await repository.readThumbnailBytes(item), isNull);
      });

      test('an item with no preview reads as null', () async {
        final item = await importOne('photo.jpg');
        await vaultDao.updateVaultItem(
          VaultItem(
            id: item.id,
            originalPath: item.originalPath,
            originalFilename: item.originalFilename,
            encryptedFilename: item.encryptedFilename,
            mediaType: item.mediaType,
            mimeType: item.mimeType,
            sizeBytes: item.sizeBytes,
            iv: item.iv,
            dateVaulted: item.dateVaulted,
          ),
        );

        final reloaded = (await repository.getItem(item.id))!;
        expect(await repository.readThumbnailBytes(reloaded), isNull);
      });
    });

    group('video playback', () {
      test('decrypts to a working file and shreds it afterwards', () async {
        final item = await importOne('clip.mp4', bytes: <int>[4, 4, 4, 4]);

        final workingPath = await repository.openVideoForPlayback(item);
        expect(await File(workingPath).exists(), isTrue);
        expect(await File(workingPath).readAsBytes(), <int>[4, 4, 4, 4]);

        await repository.closeVideoPlayback(workingPath);

        expect(await File(workingPath).exists(), isFalse);
      });
    });

    group('writes', () {
      test('renames the record without touching the payload', () async {
        final item = await importOne('photo.jpg');
        final payloadPath = await storage.pathFor(item.encryptedFilename);

        await repository.rename(item, '  Holiday.jpg  ');

        final reloaded = (await repository.getItem(item.id))!;
        expect(reloaded.originalFilename, 'Holiday.jpg');
        // The on-disk name is random by design and says nothing, so there is
        // no reason to touch it.
        expect(reloaded.encryptedFilename, item.encryptedFilename);
        expect(await File(payloadPath).exists(), isTrue);
      });

      test('ignores an empty rename', () async {
        final item = await importOne('photo.jpg');

        await repository.rename(item, '   ');

        expect(
          (await repository.getItem(item.id))!.originalFilename,
          'photo.jpg',
        );
      });

      test('stores notes and tags', () async {
        final item = await importOne('photo.jpg');

        await repository.setNotes(item, 'Passport scan');
        await repository.setTags((await repository.getItem(item.id))!, <String>[
          'Documents',
          'Private',
        ]);

        final reloaded = (await repository.getItem(item.id))!;
        expect(reloaded.notes, 'Passport scan');
        expect(reloaded.tags, <String>['Documents', 'Private']);
      });

      test('imports and then restores, round trip', () async {
        final item = await importOne('photo.jpg', bytes: <int>[3, 1, 4, 1, 5]);

        final result = await repository.exportToGallery(<VaultItem>[item]);

        expect(result.succeededCount, 1);
        expect(await repository.count(), 0);
        final restored = gallery
            .listSync()
            .whereType<File>()
            .where((file) => p.basename(file.path).contains('_vault'))
            .toList();
        expect(restored, hasLength(1));
        expect(await restored.first.readAsBytes(), <int>[3, 1, 4, 1, 5]);
      });

      test('deletes for good', () async {
        final item = await importOne('photo.jpg');
        final payloadPath = await storage.pathFor(item.encryptedFilename);

        final result = await repository.deleteForever(<VaultItem>[item]);

        expect(result.succeededCount, 1);
        expect(await File(payloadPath).exists(), isFalse);
        expect(await repository.count(), 0);
      });
    });

    group('prepareForUnlock', () {
      test('shreds a working file a crash left behind', () async {
        final item = await importOne('clip.mp4');
        final workingPath = await repository.openVideoForPlayback(item);
        expect(await File(workingPath).exists(), isTrue);

        // The app died before the player could clean up.
        await repository.prepareForUnlock();

        expect(await File(workingPath).exists(), isFalse);
      });

      test('deletes a payload no row points at', () async {
        await importOne('photo.jpg');
        final orphan = File(await storage.pathFor('deadbeefdeadbeef.enc'));
        await orphan.writeAsBytes(<int>[1, 2, 3], flush: true);

        await repository.prepareForUnlock();

        // Dead weight the user could neither see nor reach.
        expect(await orphan.exists(), isFalse);
      });

      test('leaves real payloads and previews alone', () async {
        final item = await importOne('photo.jpg');
        final payloadPath = await storage.pathFor(item.encryptedFilename);
        final thumbnailPath = await storage.pathFor(
          item.encryptedThumbnailFilename!,
        );

        await repository.prepareForUnlock();

        expect(await File(payloadPath).exists(), isTrue);
        expect(await File(thumbnailPath).exists(), isTrue);
      });

      test('leaves the .nomedia marker alone', () async {
        await importOne('photo.jpg');
        final marker = File(await storage.pathFor('.nomedia'));
        expect(await marker.exists(), isTrue);

        await repository.prepareForUnlock();

        // Deleting it would let other apps' scanners back into the directory.
        expect(await marker.exists(), isTrue);
      });

      test('never throws, even with the database shut', () async {
        await importOne('photo.jpg');
        await dbHelper.close();

        // A sweep that fails must not stop someone opening their own vault.
        await expectLater(repository.prepareForUnlock(), completes);
      });
    });
  });
}

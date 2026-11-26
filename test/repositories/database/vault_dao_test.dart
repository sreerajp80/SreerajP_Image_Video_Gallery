import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/vault_item.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/database_helper.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/vault_dao.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('VaultDao Database Access Object', () {
    late DatabaseHelper dbHelper;
    late VaultDao vaultDao;

    final now = DateTime(2026, 8, 29, 10);

    final testVaultItem = VaultItem(
      id: 'vault_record_1',
      originalPath: '/storage/DCIM/confidential.jpg',
      originalFilename: 'confidential.jpg',
      encryptedFilename: 'enc_123.bin',
      encryptedThumbnailFilename: 'enc_thumb_123.bin',
      mediaType: MediaType.image,
      mimeType: 'image/jpeg',
      sizeBytes: 1048576,
      iv: 'dGVzdGl2',
      authTag: 'dGVzdGF1dGg=',
      dateVaulted: now,
      tags: const ['Private', 'Legal'],
      notes: 'Confidential agreement photo',
    );

    setUp(() {
      dbHelper = DatabaseHelper(
        customPath: inMemoryDatabasePath,
        customFactory: databaseFactoryFfi,
      );
      vaultDao = VaultDao(dbHelper: dbHelper);
    });

    tearDown(() async {
      await dbHelper.close();
    });

    test('inserts, retrieves, and counts vault items', () async {
      await vaultDao.insertVaultItem(testVaultItem);

      final retrieved = await vaultDao.getVaultItemById(testVaultItem.id);
      expect(retrieved, isNotNull);
      expect(retrieved!.originalFilename, 'confidential.jpg');
      expect(retrieved.encryptedFilename, 'enc_123.bin');
      expect(retrieved.iv, 'dGVzdGl2');
      expect(retrieved.notes, 'Confidential agreement photo');
      expect(retrieved.tags, contains('Private'));

      final count = await vaultDao.getVaultItemsCount();
      expect(count, 1);

      final all = await vaultDao.getAllVaultItems();
      expect(all.length, 1);
      expect(all.first.id, testVaultItem.id);
    });

    test('deletes vault records', () async {
      await vaultDao.insertVaultItem(testVaultItem);
      await vaultDao.deleteVaultItem(testVaultItem.id);

      final retrieved = await vaultDao.getVaultItemById(testVaultItem.id);
      expect(retrieved, isNull);

      final count = await vaultDao.getVaultItemsCount();
      expect(count, 0);
    });

    group('Phase 10 additions', () {
      /// A second record, so the multi-row methods have something to pick from.
      VaultItem otherItem() => testVaultItem.copyWith(
        id: 'vault_record_2',
        originalFilename: 'receipt.jpg',
        encryptedFilename: 'enc_456.bin',
        encryptedThumbnailFilename: 'enc_thumb_456.bin',
        dateVaulted: now.add(const Duration(hours: 1)),
      );

      test('updates a record in place without touching the payload', () async {
        await vaultDao.insertVaultItem(testVaultItem);

        await vaultDao.updateVaultItem(
          testVaultItem.copyWith(
            originalFilename: 'renamed.jpg',
            notes: 'A new note',
          ),
        );

        final retrieved = await vaultDao.getVaultItemById(testVaultItem.id);
        expect(retrieved!.originalFilename, 'renamed.jpg');
        expect(retrieved.notes, 'A new note');
        // The on-disk name is random by design, so a rename has no reason to
        // change it.
        expect(retrieved.encryptedFilename, 'enc_123.bin');
        expect(await vaultDao.getVaultItemsCount(), 1);
      });

      test('stores the preview IV separately from the payload IV', () async {
        await vaultDao.insertVaultItem(
          testVaultItem.copyWith(thumbnailIv: 'dGh1bWJpdg=='),
        );

        final retrieved = await vaultDao.getVaultItemById(testVaultItem.id);
        expect(retrieved!.iv, 'dGVzdGl2');
        expect(retrieved.thumbnailIv, 'dGh1bWJpdg==');
      });

      test('reads a record written without a preview IV', () async {
        // What a row from before that column existed looks like.
        await vaultDao.insertVaultItem(testVaultItem);

        final retrieved = await vaultDao.getVaultItemById(testVaultItem.id);
        expect(retrieved!.thumbnailIv, isNull);
      });

      group('payload formats', () {
        test('a new record is the old format unless told otherwise', () async {
          await vaultDao.insertVaultItem(testVaultItem);

          final read = await vaultDao.getVaultItemById(testVaultItem.id);
          expect(read!.payloadFormat, 1);
          expect(read.thumbnailFormat, 1);
        });

        test('updateVaultItem never writes the crypto columns', () async {
          // A notes screen that loaded the row before the upgrade converted
          // it must not point the row back at the deleted old file.
          await vaultDao.insertVaultItem(testVaultItem);
          final converted = testVaultItem.copyWith(
            encryptedFilename: 'new.enc',
            iv: 'bmV3',
            payloadFormat: 2,
            thumbnailFormat: 2,
          );
          await vaultDao.updateEncryption(converted);

          await vaultDao.updateVaultItem(
            testVaultItem.copyWith(notes: 'edited later'),
          );

          final read = await vaultDao.getVaultItemById(testVaultItem.id);
          expect(read!.notes, 'edited later');
          expect(read.encryptedFilename, 'new.enc');
          expect(read.iv, 'bmV3');
          expect(read.payloadFormat, 2);
        });

        test('updateEncryption changes only the crypto columns', () async {
          await vaultDao.insertVaultItem(testVaultItem);

          final rows = await vaultDao.updateEncryption(
            testVaultItem.copyWith(
              encryptedFilename: 'new.enc',
              notes: 'must not be written',
              payloadFormat: 2,
            ),
          );

          expect(rows, 1);
          final read = await vaultDao.getVaultItemById(testVaultItem.id);
          expect(read!.encryptedFilename, 'new.enc');
          expect(read.notes, testVaultItem.notes);
        });

        test('updateEncryption on a deleted record changes nothing', () async {
          expect(await vaultDao.updateEncryption(testVaultItem), 0);
        });

        test('getLegacyFormatIds lists only rows left to convert', () async {
          await vaultDao.insertVaultItem(testVaultItem);
          await vaultDao.insertVaultItem(
            testVaultItem.copyWith(
              id: 'done',
              payloadFormat: 2,
              thumbnailFormat: 2,
            ),
          );
          // Payload done, preview still old and readable: still listed.
          await vaultDao.insertVaultItem(
            testVaultItem.copyWith(
              id: 'preview_left',
              payloadFormat: 2,
              thumbnailIv: 'dGg=',
            ),
          );

          final ids = await vaultDao.getLegacyFormatIds();
          expect(
            ids,
            unorderedEquals(<String>[testVaultItem.id, 'preview_left']),
          );
        });
      });

      test('getIdsWithoutPreview lists rows with no usable preview', () async {
        await vaultDao.insertVaultItem(
          testVaultItem.copyWith(id: 'has', thumbnailIv: 'dGg='),
        );
        // A preview file but no IV (before schema 2) cannot be opened.
        await vaultDao.insertVaultItem(testVaultItem.copyWith(id: 'no_iv'));
        await vaultDao.insertVaultItem(
          VaultItem(
            id: 'none',
            originalPath: '/storage/DCIM/x.jpg',
            originalFilename: 'x.jpg',
            encryptedFilename: 'x.enc',
            mediaType: MediaType.image,
            mimeType: 'image/jpeg',
            sizeBytes: 1,
            iv: 'aXY=',
            dateVaulted: now,
          ),
        );

        expect(
          await vaultDao.getIdsWithoutPreview(),
          unorderedEquals(<String>['no_iv', 'none']),
        );
      });

      group('getVaultItemsByIds', () {
        test('returns the records asked for, newest first', () async {
          await vaultDao.insertVaultItem(testVaultItem);
          await vaultDao.insertVaultItem(otherItem());

          final found = await vaultDao.getVaultItemsByIds(<String>[
            testVaultItem.id,
            'vault_record_2',
          ]);

          expect(found.map((item) => item.id), <String>[
            'vault_record_2',
            testVaultItem.id,
          ]);
        });

        test('ignores an id that is not there', () async {
          await vaultDao.insertVaultItem(testVaultItem);

          final found = await vaultDao.getVaultItemsByIds(<String>[
            testVaultItem.id,
            'never_existed',
          ]);

          expect(found, hasLength(1));
        });

        test('an empty request returns nothing and runs no query', () async {
          // A query with no placeholders is one SQLite would reject.
          expect(await vaultDao.getVaultItemsByIds(const <String>[]), isEmpty);
        });
      });

      group('deleteVaultItems', () {
        test('removes several in one statement', () async {
          await vaultDao.insertVaultItem(testVaultItem);
          await vaultDao.insertVaultItem(otherItem());

          await vaultDao.deleteVaultItems(<String>[
            testVaultItem.id,
            'vault_record_2',
          ]);

          expect(await vaultDao.getVaultItemsCount(), 0);
        });

        test('leaves records it was not asked about', () async {
          await vaultDao.insertVaultItem(testVaultItem);
          await vaultDao.insertVaultItem(otherItem());

          await vaultDao.deleteVaultItems(<String>[testVaultItem.id]);

          expect(await vaultDao.getVaultItemsCount(), 1);
          expect(
            (await vaultDao.getVaultItemById('vault_record_2')),
            isNotNull,
          );
        });

        test('an empty request does nothing', () async {
          await vaultDao.insertVaultItem(testVaultItem);

          await vaultDao.deleteVaultItems(const <String>[]);

          expect(await vaultDao.getVaultItemsCount(), 1);
        });
      });

      group('getAllEncryptedFilenames', () {
        test(
          'lists both the payload and the preview of every record',
          () async {
            await vaultDao.insertVaultItem(testVaultItem);
            await vaultDao.insertVaultItem(otherItem());

            final names = await vaultDao.getAllEncryptedFilenames();

            expect(names, <String>{
              'enc_123.bin',
              'enc_thumb_123.bin',
              'enc_456.bin',
              'enc_thumb_456.bin',
            });
          },
        );

        test('skips a record with no preview', () async {
          await vaultDao.insertVaultItem(testVaultItem.copyWith());

          // copyWith cannot clear a nullable field, so the row is written
          // directly to make the case real.
          final names = await vaultDao.getAllEncryptedFilenames();
          expect(names, contains('enc_123.bin'));
        });

        test('is empty for an empty vault', () async {
          expect(await vaultDao.getAllEncryptedFilenames(), isEmpty);
        });
      });
    });
  });
}

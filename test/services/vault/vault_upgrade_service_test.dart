import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/vault_item.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/database_helper.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/vault_dao.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_crypto_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_naming_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_shredder_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_storage_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_upgrade_service.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'fake_vault_channel.dart';

/// A DAO that acts as if the item was deleted while it was being converted.
class _VanishingVaultDao extends VaultDao {
  _VanishingVaultDao({required super.dbHelper});

  @override
  Future<int> updateEncryption(VaultItem item) async => 0;
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  const legacy = AppConstants.vaultPayloadFormatLegacy;
  const streaming = AppConstants.vaultPayloadFormatStreaming;

  late Directory root;
  late DatabaseHelper dbHelper;
  late VaultDao vaultDao;
  late FakeVaultChannel channel;
  late VaultStorageService storage;
  late VaultCryptoService crypto;
  late VaultShredderService shredder;

  VaultUpgradeService serviceWith(VaultDao dao) => VaultUpgradeService(
    vaultDao: dao,
    crypto: crypto,
    storage: storage,
    shredder: shredder,
  );

  setUp(() async {
    root = await Directory.systemTemp.createTemp('vault_upgrade_test');
    dbHelper = DatabaseHelper(
      customPath: inMemoryDatabasePath,
      customFactory: databaseFactoryFfi,
    );
    vaultDao = VaultDao(dbHelper: dbHelper);
    channel = FakeVaultChannel()..nativeShredSucceeds = true;
    storage = VaultStorageService(rootOverride: root);
    crypto = VaultCryptoService(channel: channel, storage: storage);
    shredder = VaultShredderService(channel: channel, random: Random(3));
  });

  tearDown(() async {
    await dbHelper.close();
    if (await root.exists()) await root.delete(recursive: true);
  });

  /// Adds an item the way an older app version wrote it: format 1.
  Future<VaultItem> addOldItem({
    String id = 'v1',
    MediaType mediaType = MediaType.image,
    List<int> bytes = const <int>[1, 2, 3, 4],
    bool withThumbnail = true,
  }) async {
    channel.writeFormat = legacy;
    final payload = await crypto.encryptBytesToPayload(
      Uint8List.fromList(bytes),
    );
    final thumbnail = withThumbnail
        ? await crypto.encryptThumbnailBytes(Uint8List.fromList(<int>[9, 9]))
        : null;
    channel.writeFormat = streaming;

    final item = VaultItem(
      id: id,
      originalPath: '/storage/DCIM/$id.jpg',
      originalFilename: '$id.jpg',
      encryptedFilename: payload.fileName,
      encryptedThumbnailFilename: thumbnail?.fileName,
      mediaType: mediaType,
      mimeType: mediaType == MediaType.video ? 'video/mp4' : 'image/jpeg',
      sizeBytes: payload.cipherSizeBytes,
      iv: payload.iv,
      thumbnailIv: thumbnail?.iv,
      dateVaulted: DateTime(2026, 11, 2),
      notes: 'keep me',
    );
    await vaultDao.insertVaultItem(item);
    return item;
  }

  Future<bool> exists(String name) async =>
      File(await storage.pathFor(name)).exists();

  test('converts a photo and its preview, and drops the old files', () async {
    final old = await addOldItem();

    final converted = await serviceWith(
      vaultDao,
    ).upgradeAll(shouldContinue: () => true);

    expect(converted, 1);
    final row = (await vaultDao.getVaultItemById(old.id))!;
    expect(row.payloadFormat, streaming);
    expect(row.thumbnailFormat, streaming);
    expect(row.encryptedFilename, isNot(old.encryptedFilename));
    expect(row.notes, 'keep me');

    // The new files open, with the same bytes as before.
    final plain = await crypto.decryptToMemory(
      fileName: row.encryptedFilename,
      iv: row.iv,
      format: row.payloadFormat,
    );
    expect(plain, <int>[1, 2, 3, 4]);
    final preview = await crypto.decryptToMemory(
      fileName: row.encryptedThumbnailFilename!,
      iv: row.thumbnailIv!,
      format: row.thumbnailFormat,
    );
    expect(preview, <int>[9, 9]);

    expect(await exists(old.encryptedFilename), isFalse);
    expect(await exists(old.encryptedThumbnailFilename!), isFalse);
  });

  test('converts a video through a working file it shreds', () async {
    final old = await addOldItem(
      id: 'clip',
      mediaType: MediaType.video,
      withThumbnail: false,
    );

    await serviceWith(vaultDao).upgradeAll(shouldContinue: () => true);

    final row = (await vaultDao.getVaultItemById(old.id))!;
    expect(row.payloadFormat, streaming);
    final workingName = VaultNamingService().workingNameFor(
      old.encryptedFilename,
    );
    expect(await exists(workingName), isFalse);
    expect(channel.shredded, contains(await storage.pathFor(workingName)));
  });

  test('leaves items already in the new format alone', () async {
    final old = await addOldItem();
    await serviceWith(vaultDao).upgradeAll(shouldContinue: () => true);
    final once = (await vaultDao.getVaultItemById(old.id))!;

    final again = await serviceWith(
      vaultDao,
    ).upgradeAll(shouldContinue: () => true);

    expect(again, 0);
    expect(await vaultDao.getVaultItemById(old.id), once);
  });

  test('stops when told to, and converts nothing more', () async {
    final old = await addOldItem();

    final converted = await serviceWith(
      vaultDao,
    ).upgradeAll(shouldContinue: () => false);

    expect(converted, 0);
    final row = (await vaultDao.getVaultItemById(old.id))!;
    expect(row.payloadFormat, legacy);
    expect(await exists(old.encryptedFilename), isTrue);
  });

  test(
    'a failure keeps the old row and file, and leaves no new file',
    () async {
      final old = await addOldItem(withThumbnail: false);
      final before = (await storage.vaultDirectory())
          .listSync()
          .map((e) => p.basename(e.path))
          .toSet();
      channel.failEncrypt = true;

      final converted = await serviceWith(
        vaultDao,
      ).upgradeAll(shouldContinue: () => true);

      expect(converted, 0);
      expect(await vaultDao.getVaultItemById(old.id), old);
      expect(await exists(old.encryptedFilename), isTrue);
      final after = (await storage.vaultDirectory())
          .listSync()
          .map((e) => p.basename(e.path))
          .toSet();
      expect(after, before);
    },
  );

  test('an item deleted meanwhile gets its new files removed', () async {
    final old = await addOldItem();
    final before = (await storage.vaultDirectory())
        .listSync()
        .map((e) => p.basename(e.path))
        .toSet();

    final converted = await serviceWith(
      _VanishingVaultDao(dbHelper: dbHelper),
    ).upgradeAll(shouldContinue: () => true);

    expect(converted, 0);
    final after = (await storage.vaultDirectory())
        .listSync()
        .map((e) => p.basename(e.path))
        .toSet();
    // Only what was there before: the new files are gone, and the old ones
    // were not touched, because the row was never moved off them.
    expect(after, before);
    expect(await exists(old.encryptedFilename), isTrue);
  });

  test('a second call during a run returns at once', () async {
    await addOldItem();
    final service = serviceWith(vaultDao);

    final first = service.upgradeAll(shouldContinue: () => true);
    final second = await service.upgradeAll(shouldContinue: () => true);
    await service.waitUntilIdle();

    expect(second, 0);
    expect(await first, 1);
    expect(service.isRunning, isFalse);
  });

  test('every converted file is read back before the old one goes', () async {
    final old = await addOldItem(withThumbnail: false);

    await serviceWith(vaultDao).upgradeAll(shouldContinue: () => true);

    final row = (await vaultDao.getVaultItemById(old.id))!;
    expect(
      channel.digested,
      contains(await storage.pathFor(row.encryptedFilename)),
    );
  });

  test(
    'a file that does not read back keeps the old one, and stops the run',
    () async {
      final first = await addOldItem(id: 'a', withThumbnail: false);
      final second = await addOldItem(id: 'b', withThumbnail: false);
      final before = (await storage.vaultDirectory())
          .listSync()
          .map((e) => p.basename(e.path))
          .toSet();
      channel.corruptNextWrites = 1;

      final converted = await serviceWith(
        vaultDao,
      ).upgradeAll(shouldContinue: () => true);

      expect(converted, 0);
      // Both rows untouched, both old files still there, no new file left.
      expect(await vaultDao.getVaultItemById(first.id), first);
      expect(await vaultDao.getVaultItemById(second.id), second);
      final after = (await storage.vaultDirectory())
          .listSync()
          .map((e) => p.basename(e.path))
          .toSet();
      expect(after, before);
      // Stopped after the first failure: only one read-back was attempted.
      expect(channel.digested, hasLength(1));
    },
  );

  test('a preview that does not read back keeps the old preview', () async {
    final old = await addOldItem();
    var writes = 0;
    channel.onWrite = () {
      writes++;
      // Write 1 is the payload, write 2 the preview.
      if (writes == 2) channel.corruptNextWrites = 1;
    };

    await serviceWith(vaultDao).upgradeAll(shouldContinue: () => true);

    final row = (await vaultDao.getVaultItemById(old.id))!;
    expect(row.payloadFormat, streaming);
    expect(row.thumbnailFormat, legacy);
    expect(row.encryptedThumbnailFilename, old.encryptedThumbnailFilename);
    expect(await exists(old.encryptedThumbnailFilename!), isTrue);
  });
}

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/vault_item.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/database_helper.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/vault_dao.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_crypto_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_naming_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_preview_backfill_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_shredder_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_storage_service.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../video/fake_video_tools_channel.dart';
import 'fake_vault_channel.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Directory root;
  late DatabaseHelper dbHelper;
  late VaultDao vaultDao;
  late FakeVaultChannel channel;
  late FakeVideoToolsChannel videoTools;
  late VaultStorageService storage;
  late VaultCryptoService crypto;
  late VaultPreviewBackfillService service;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('vault_backfill_test');
    dbHelper = DatabaseHelper(
      customPath: inMemoryDatabasePath,
      customFactory: databaseFactoryFfi,
    );
    vaultDao = VaultDao(dbHelper: dbHelper);
    channel = FakeVaultChannel()..nativeShredSucceeds = true;
    videoTools = FakeVideoToolsChannel(
      frameBytes: Uint8List.fromList(<int>[4, 4, 4]),
    );
    storage = VaultStorageService(rootOverride: root);
    crypto = VaultCryptoService(
      channel: channel,
      storage: storage,
      naming: VaultNamingService(random: Random(5)),
    );
    service = VaultPreviewBackfillService(
      vaultDao: vaultDao,
      crypto: crypto,
      storage: storage,
      shredder: VaultShredderService(channel: channel, random: Random(8)),
      videoTools: videoTools,
    );
  });

  tearDown(() async {
    await dbHelper.close();
    if (await root.exists()) await root.delete(recursive: true);
  });

  Future<VaultItem> addItem(
    String id, {
    MediaType type = MediaType.image,
    bool withPreview = false,
  }) async {
    final payload = await crypto.encryptBytesToPayload(
      Uint8List.fromList(<int>[1, 2, 3, 4, 5]),
    );
    final preview = withPreview
        ? await crypto.encryptThumbnailBytes(Uint8List.fromList(<int>[8, 8]))
        : null;
    final item = VaultItem(
      id: id,
      originalPath: '/storage/emulated/0/DCIM/$id.jpg',
      originalFilename: '$id.jpg',
      encryptedFilename: payload.fileName,
      encryptedThumbnailFilename: preview?.fileName,
      mediaType: type,
      mimeType: type == MediaType.video ? 'video/mp4' : 'image/jpeg',
      sizeBytes: payload.cipherSizeBytes,
      iv: payload.iv,
      thumbnailIv: preview?.iv,
      payloadFormat: payload.format,
      thumbnailFormat: payload.format,
      dateVaulted: DateTime(2026, 11, 2),
      notes: 'keep me',
    );
    await vaultDao.insertVaultItem(item);
    return item;
  }

  Future<List<int>> previewOf(String id) async {
    final row = (await vaultDao.getVaultItemById(id))!;
    return crypto.decryptToMemory(
      fileName: row.encryptedThumbnailFilename!,
      iv: row.thumbnailIv!,
      format: row.thumbnailFormat,
    );
  }

  test('a photo without a preview gets one made from its payload', () async {
    await addItem('a');

    final added = await service.fillAll(shouldContinue: () => true);

    expect(added, 1);
    expect(await previewOf('a'), <int>[0xFF, 0xD8, 7, 7]);
    expect((await vaultDao.getVaultItemById('a'))!.notes, 'keep me');
    // Read back before it was recorded.
    expect(channel.digested, isNotEmpty);
  });

  test('a video gets a frame through a working file it shreds', () async {
    await addItem('v', type: MediaType.video);

    await service.fillAll(shouldContinue: () => true);

    expect(await previewOf('v'), <int>[4, 4, 4]);
    expect(videoTools.requestedPositions, <int>[0]);
    final leftovers = (await storage.vaultDirectory())
        .listSync()
        .map((e) => p.basename(e.path))
        .where(VaultNamingService.isWorkingFile);
    expect(leftovers, isEmpty);
  });

  test('items that already have a preview are left alone', () async {
    await addItem('a', withPreview: true);

    final added = await service.fillAll(shouldContinue: () => true);

    expect(added, 0);
    expect(channel.payloadPreviewCalls, 0);
    expect(await previewOf('a'), <int>[8, 8]);
  });

  test('a picture Android cannot decode keeps its icon, quietly', () async {
    await addItem('a');
    channel.payloadPreview = null;

    final added = await service.fillAll(shouldContinue: () => true);

    expect(added, 0);
    expect(
      (await vaultDao.getVaultItemById('a'))!.encryptedThumbnailFilename,
      isNull,
    );
  });

  test('a preview that does not read back is not recorded or kept', () async {
    final item = await addItem('a');
    final before = (await storage.vaultDirectory())
        .listSync()
        .map((e) => p.basename(e.path))
        .toSet();
    channel.corruptNextWrites = 1;

    final added = await service.fillAll(shouldContinue: () => true);

    expect(added, 0);
    expect(await vaultDao.getVaultItemById('a'), item);
    final after = (await storage.vaultDirectory())
        .listSync()
        .map((e) => p.basename(e.path))
        .toSet();
    expect(after, before);
  });

  test('stops when told to', () async {
    await addItem('a');

    final added = await service.fillAll(shouldContinue: () => false);

    expect(added, 0);
    expect(channel.payloadPreviewCalls, 0);
  });

  test('a second call during a run returns at once', () async {
    await addItem('a');

    final first = service.fillAll(shouldContinue: () => true);
    final second = await service.fillAll(shouldContinue: () => true);
    await service.waitUntilIdle();

    expect(second, 0);
    expect(await first, 1);
  });
}

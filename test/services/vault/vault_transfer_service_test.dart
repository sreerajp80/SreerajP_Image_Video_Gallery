import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/errors/app_exception.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/vault_item.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/database_helper.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/vault_dao.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_crypto_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_naming_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_preview_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_shredder_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_storage_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_transfer_service.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'fake_vault_channel.dart';

class _FakePreviewService implements VaultPreviewService {
  @override
  Future<Uint8List?> buildPreview(MediaItem item) async => null;
}

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

  group('VaultTransferService', () {
    late Directory root;
    late Directory staging;
    late DatabaseHelper dbHelper;
    late VaultDao vaultDao;
    late FakeVaultChannel channel;
    late VaultStorageService storage;
    late VaultCryptoService crypto;
    late bool ready;

    VaultTransferService serviceWith(VaultDao dao) => VaultTransferService(
      crypto: crypto,
      storage: storage,
      shredder: VaultShredderService(channel: channel, random: Random(2)),
      preview: _FakePreviewService(),
      vaultDao: dao,
      isReady: () async => ready,
      random: Random(5),
    );

    setUp(() async {
      root = await Directory.systemTemp.createTemp('vault_transfer_test');
      staging = Directory(p.join(root.path, 'staging'))..createSync();
      dbHelper = DatabaseHelper(
        customPath: inMemoryDatabasePath,
        customFactory: databaseFactoryFfi,
      );
      vaultDao = VaultDao(dbHelper: dbHelper);
      channel = FakeVaultChannel()..nativeShredSucceeds = true;
      storage = VaultStorageService(
        rootOverride: Directory(p.join(root.path, 'vault')),
      );
      crypto = VaultCryptoService(
        channel: channel,
        storage: storage,
        naming: VaultNamingService(random: Random(9)),
      );
      ready = true;
    });

    tearDown(() async {
      await dbHelper.close();
      if (await root.exists()) await root.delete(recursive: true);
    });

    Future<File> stage(String name, {int byteCount = 64}) async {
      final file = File(p.join(staging.path, name));
      await file.writeAsBytes(
        List<int>.generate(byteCount, (i) => (i * 7) % 256),
        flush: true,
      );
      return file;
    }

    test(
      'puts a received file into the vault and removes the plain copy',
      () async {
        final staged = await stage('a.jpg');

        final item = await serviceWith(vaultDao).importReceived(
          staged: staged,
          displayName: 'a.jpg',
          mimeType: 'image/jpeg',
          mediaType: MediaType.image,
          tags: const <String>['Trip'],
          notes: 'beach',
        );

        expect(await staged.exists(), isFalse);
        final stored = await vaultDao.getVaultItemById(item.id);
        expect(stored, isNotNull);
        expect(stored!.originalFilename, 'a.jpg');
        expect(stored.tags, <String>['Trip']);
        expect(stored.notes, 'beach');
        expect(
          await File(await storage.pathFor(stored.encryptedFilename)).exists(),
          isTrue,
        );
      },
    );

    test(
      'refuses when this phone has no vault, and still removes the copy',
      () async {
        ready = false;
        final staged = await stage('b.jpg');

        await expectLater(
          serviceWith(vaultDao).importReceived(
            staged: staged,
            displayName: 'b.jpg',
            mimeType: 'image/jpeg',
            mediaType: MediaType.image,
          ),
          throwsA(isA<VaultException>()),
        );
        expect(await staged.exists(), isFalse);
        expect(await vaultDao.getVaultItemsCount(), 0);
      },
    );

    test('a failed record write leaves no payload and no plain copy', () async {
      final staged = await stage('c.jpg');

      await expectLater(
        serviceWith(_FailingVaultDao(dbHelper: dbHelper)).importReceived(
          staged: staged,
          displayName: 'c.jpg',
          mimeType: 'image/jpeg',
          mediaType: MediaType.image,
        ),
        throwsA(isA<AppException>()),
      );
      expect(await staged.exists(), isFalse);
      final vaultDir = await storage.vaultDirectory();
      final payloads = vaultDir
          .listSync()
          .whereType<File>()
          .where((f) => !p.basename(f.path).startsWith('.'))
          .toList();
      expect(payloads, isEmpty);
    });

    test(
      'a sent item opens to its original bytes and the copy can be shredded',
      () async {
        final staged = await stage('d.jpg', byteCount: 100);
        final original = await staged.readAsBytes();
        final service = serviceWith(vaultDao);
        final item = await service.importReceived(
          staged: staged,
          displayName: 'd.jpg',
          mimeType: 'image/jpeg',
          mediaType: MediaType.image,
        );

        final plain = await service.openPlain(item);
        expect(await plain.readAsBytes(), original);

        await service.closePlain(plain);
        expect(await plain.exists(), isFalse);
      },
    );
  });
}

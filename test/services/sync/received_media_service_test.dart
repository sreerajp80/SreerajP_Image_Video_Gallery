import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/errors/app_exception.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/transfer_manifest.dart';
import 'package:in_sreerajp_imgvidgal/models/vault_item.dart';
import 'package:in_sreerajp_imgvidgal/repositories/album_repository.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/media_dao.dart';
import 'package:in_sreerajp_imgvidgal/repositories/media_repository.dart';
import 'package:in_sreerajp_imgvidgal/repositories/tag_repository.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/received_media_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_transfer_service.dart';
import 'package:path/path.dart' as p;

import '../media/fake_media_store_channel.dart';

/// Any call means the code under test went somewhere it must not.
class _Untouched implements MediaRepository, TagRepository, AlbumRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('unexpected call: ${invocation.memberName}');
}

/// Says "already here" for every digest.
class _HasEverything implements MediaDao {
  @override
  Future<bool> hasMediaWithHash(String sha256) async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('unexpected call: ${invocation.memberName}');
}

/// Records what it was asked to put in the vault.
class _FakeVault implements VaultTransferService {
  final List<String> imported = <String>[];

  @override
  Future<VaultItem> importReceived({
    required File staged,
    required String displayName,
    required String mimeType,
    required MediaType mediaType,
    DateTime? dateTaken,
    List<String> tags = const <String>[],
    String? notes,
  }) async {
    imported.add(displayName);
    await staged.delete();
    return VaultItem(
      id: 'v1',
      originalPath: '',
      originalFilename: displayName,
      encryptedFilename: 'x.enc',
      mediaType: mediaType,
      mimeType: mimeType,
      sizeBytes: 1,
      iv: 'iv',
      dateVaulted: DateTime(2026, 11, 11),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('unexpected call: ${invocation.memberName}');
}

const TransferEntry _vaultEntry = TransferEntry(
  sourceId: 's1',
  displayName: 'secret.jpg',
  mimeType: 'image/jpeg',
  mediaTypeName: 'image',
  sizeBytes: 3,
  sha256: 'abc',
  vault: true,
);

void main() {
  late Directory root;
  late FakeMediaStoreChannel store;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('received_media_test');
    store = FakeMediaStoreChannel();
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  ReceivedMediaService serviceWith({VaultTransferService? vault}) {
    final untouched = _Untouched();
    return ReceivedMediaService(
      mediaStore: store,
      mediaRepository: untouched,
      mediaDao: _HasEverything(),
      tagRepository: untouched,
      albumRepository: untouched,
      vault: vault,
    );
  }

  Future<File> staged() async {
    final file = File(p.join(root.path, 'staged.bin'));
    await file.writeAsBytes(<int>[1, 2, 3]);
    return file;
  }

  group('ReceivedMediaService and vault files', () {
    test('a vault file goes to the vault, never to MediaStore', () async {
      final vault = _FakeVault();
      final service = serviceWith(vault: vault);

      await service.commit(_vaultEntry, await staged());

      expect(vault.imported, <String>['secret.jpg']);
      expect(store.publishedNames, isEmpty);
      expect(service.vaultReceivedCount, 1);
    });

    test('with no vault here, a vault file is refused and removed', () async {
      final service = serviceWith();
      final file = await staged();

      await expectLater(
        service.commit(_vaultEntry, file),
        throwsA(isA<VaultException>()),
      );
      expect(store.publishedNames, isEmpty);
      expect(await file.exists(), isFalse);
    });

    test(
      'a vault file is taken even when the gallery has the same photo',
      () async {
        final service = serviceWith(vault: _FakeVault());

        expect(await service.alreadyHave(_vaultEntry), isFalse);
        expect(
          await service.alreadyHave(
            const TransferEntry(
              sourceId: 's2',
              displayName: 'open.jpg',
              mimeType: 'image/jpeg',
              mediaTypeName: 'image',
              sizeBytes: 3,
              sha256: 'abc',
            ),
          ),
          isTrue,
        );
      },
    );
  });
}

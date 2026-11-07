import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/errors/app_exception.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/vault/vault_import_result.dart';
import 'package:in_sreerajp_imgvidgal/models/vault/vault_security_settings.dart';
import 'package:in_sreerajp_imgvidgal/models/vault_item.dart';
import 'package:in_sreerajp_imgvidgal/providers/backup_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/vault_providers.dart';
import 'package:in_sreerajp_imgvidgal/repositories/vault_repository.dart';
import 'package:in_sreerajp_imgvidgal/services/backup/document_picker_channel.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_auth_service.dart';
import 'package:flutter_riverpod/misc.dart';

VaultItem _vaultItem(String id, MediaType type) => VaultItem(
  id: id,
  originalPath: '/storage/emulated/0/DCIM/$id',
  originalFilename: id,
  encryptedFilename: '$id.enc',
  mediaType: type,
  mimeType: type == MediaType.video ? 'video/mp4' : 'image/jpeg',
  sizeBytes: 10,
  iv: 'iv',
  dateVaulted: DateTime(2026, 9, 26),
);

/// Only the calls the viewer makes are real; anything else fails the test.
class _FakeVaultRepository implements VaultRepository {
  final Map<String, VaultItem> items = <String, VaultItem>{};
  final List<String> shredded = <String>[];
  bool readThrows = false;
  bool shredThrows = false;
  Set<String> missingFolderIds = <String>{};
  String? lastFallbackFolderUri;

  @override
  Future<VaultItem?> getItem(String id) async => items[id];

  @override
  Future<Uint8List> readImageBytes(VaultItem item) async {
    if (readThrows) {
      throw const VaultException('tampered', code: 'payload_tampered');
    }
    return Uint8List.fromList(<int>[1, 2, 3]);
  }

  @override
  Future<String> openVideoForPlayback(VaultItem item) async =>
      '/data/vault/work/${item.id}.mp4';

  @override
  Future<void> closeVideoPlayback(String workingPath, {int? shredPasses}) {
    shredded.add(workingPath);
    if (shredThrows) return Future<void>.error(StateError('busy'));
    return Future<void>.value();
  }

  @override
  List<VaultItem> itemsWithMissingFolder(List<VaultItem> items) =>
      items.where((item) => missingFolderIds.contains(item.id)).toList();

  @override
  Future<VaultBatchResult> exportToGallery(
    List<VaultItem> items, {
    int? shredPasses,
    String? fallbackFolderUri,
    void Function(int done, int total)? onProgress,
  }) async {
    lastFallbackFolderUri = fallbackFolderUri;
    return VaultBatchResult(
      succeededIds: items.map((item) => item.id).toList(),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthService implements VaultAuthService {
  @override
  Future<VaultSecuritySettings> readSettings() async =>
      VaultSecuritySettings.defaults;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePicker implements DocumentPickerChannel {
  String? folder;
  bool throwsNoPicker = false;

  @override
  Future<String?> openFolder() async {
    if (throwsNoPicker) {
      throw const DocumentPickerException('no_picker', 'none');
    }
    return folder;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeVaultRepository repository;
  late _FakePicker picker;
  late ProviderContainer container;
  late VaultViewerActions actions;

  setUp(() {
    repository = _FakeVaultRepository()
      ..items['p'] = _vaultItem('p', MediaType.image)
      ..items['v'] = _vaultItem('v', MediaType.video);
    picker = _FakePicker();
    container = ProviderContainer(
      overrides: <Override>[
        vaultRepositoryProvider.overrideWithValue(repository),
        vaultAuthServiceProvider.overrideWithValue(_FakeAuthService()),
        documentPickerChannelProvider.overrideWithValue(picker),
      ],
    );
    addTearDown(container.dispose);
    actions = container.read(vaultViewerActionsProvider);
  });

  group('VaultViewerActions.open', () {
    test('a picture comes back as bytes, with no working file', () async {
      final opened = await actions.open('p');

      expect(opened!.item.id, 'p');
      expect(opened.imageBytes, isNotNull);
      expect(opened.videoWorkingPath, isNull);
    });

    test('a video comes back as a working file path', () async {
      final opened = await actions.open('v');

      expect(opened!.videoWorkingPath, '/data/vault/work/v.mp4');
      expect(opened.imageBytes, isNull);
    });

    test('a missing item is null, not an error', () async {
      expect(await actions.open('gone'), isNull);
    });

    test('a tampered payload surfaces as a VaultException', () async {
      repository.readThrows = true;

      await expectLater(actions.open('p'), throwsA(isA<VaultException>()));
    });
  });

  group('VaultViewerActions.discardWorkingFile', () {
    test('asks the repository to shred the file', () async {
      actions.discardWorkingFile('/data/vault/work/v.mp4');
      await Future<void>.delayed(Duration.zero);

      expect(repository.shredded, <String>['/data/vault/work/v.mp4']);
    });

    test('a failing shred is swallowed, not thrown', () async {
      repository.shredThrows = true;

      expect(() => actions.discardWorkingFile('x'), returnsNormally);
      await Future<void>.delayed(Duration.zero);
    });
  });

  group('VaultBatchController restore with a missing folder', () {
    VaultBatchController controller() =>
        container.read(vaultBatchControllerProvider.notifier);

    test('finds only the items whose folder is gone', () {
      repository.missingFolderIds = <String>{'v'};

      final missing = controller().findItemsWithMissingFolder(<VaultItem>[
        repository.items['p']!,
        repository.items['v']!,
      ]);

      expect(missing.map((item) => item.id), <String>['v']);
    });

    test('passes the picked folder through to the repository', () async {
      await controller().restore(<VaultItem>[
        repository.items['v']!,
      ], fallbackFolderUri: 'content://tree/picked');

      expect(repository.lastFallbackFolderUri, 'content://tree/picked');
    });

    test('returns the folder the user picked', () async {
      picker.folder = 'content://tree/picked';

      expect(await controller().pickRestoreFolder(), 'content://tree/picked');
    });

    test('a device with no picker gives null, like Skip', () async {
      picker.throwsNoPicker = true;

      expect(await controller().pickRestoreFolder(), isNull);
    });
  });
}

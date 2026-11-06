import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/backup/backup_manifest.dart';
import 'package:in_sreerajp_imgvidgal/models/backup/backup_payload.dart';
import 'package:in_sreerajp_imgvidgal/models/backup/restore_plan.dart';
import 'package:in_sreerajp_imgvidgal/models/backup/restore_summary.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/providers/album_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/backup_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/tag_providers.dart';
import 'package:in_sreerajp_imgvidgal/services/backup/backup_service.dart';
import 'package:in_sreerajp_imgvidgal/services/backup/restore_service.dart';

const _manifest = BackupManifest(
  payloadVersion: 1,
  schemaVersion: 2,
  appVersion: '1.0.0+1',
  createdAtMs: 1756584284000,
);

const _payload = BackupPayload(manifest: _manifest);

/// Reports one stage, then succeeds or fails.
class _FakeBackupService implements BackupService {
  bool fail = false;
  String? lastVersion;
  BackupStage? stageSeenDuringRun;

  @override
  Future<BackupResult> createBackup({
    required String password,
    required String appVersion,
    void Function(BackupStage stage)? onStage,
    DateTime? now,
  }) async {
    lastVersion = appVersion;
    onStage?.call(BackupStage.values.first);
    if (fail) throw StateError('no space');
    return const BackupResult(
      destinationUri: 'content://backup',
      bytesWritten: 10,
      payload: _payload,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Opens a fixed archive and applies it as a fixed summary.
class _FakeRestoreService implements RestoreService {
  bool failOpen = false;
  int applied = 0;

  @override
  Future<OpenedArchive?> openArchive({required String password}) async {
    if (failOpen) throw StateError('wrong password');
    return const OpenedArchive(
      payload: _payload,
      plan: RestorePlan(manifest: _manifest),
      localMedia: <MediaItem>[],
    );
  }

  @override
  Future<RestoreSummary> applyPlan(
    OpenedArchive archive, {
    void Function(int done, int total)? onProgress,
  }) async {
    applied++;
    return const RestoreSummary(tagsCreated: 2);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeBackupService backup;
  late _FakeRestoreService restore;
  late ProviderContainer container;

  setUp(() {
    backup = _FakeBackupService();
    restore = _FakeRestoreService();
    container = ProviderContainer(
      overrides: <Override>[
        backupServiceProvider.overrideWithValue(backup),
        restoreServiceProvider.overrideWithValue(restore),
        appVersionProvider.overrideWith((ref) async => '2.0.0+5'),
      ],
    );
  });

  tearDown(() => container.dispose());

  group('BackupController', () {
    test('a backup passes the app version and clears the stage', () async {
      final stages = <BackupStage?>[];
      container.listen(backupStageProvider, (_, next) => stages.add(next));

      final result = await container
          .read(backupControllerProvider.notifier)
          .createBackup('secret');

      expect(result?.bytesWritten, 10);
      expect(backup.lastVersion, '2.0.0+5');
      expect(stages, <BackupStage?>[BackupStage.values.first, null]);
      expect(container.read(backupControllerProvider).value, result);
    });

    test('a failed backup gives an error and clears the stage', () async {
      backup.fail = true;

      final result = await container
          .read(backupControllerProvider.notifier)
          .createBackup('secret');

      expect(result, isNull);
      expect(container.read(backupControllerProvider).hasError, isTrue);
      expect(container.read(backupStageProvider), isNull);
    });

    test('reset clears the result', () async {
      final notifier = container.read(backupControllerProvider.notifier);
      await notifier.createBackup('secret');
      notifier.reset();

      expect(container.read(backupControllerProvider).value, isNull);
    });
  });

  group('RestoreController', () {
    test('apply does nothing before an archive is open', () async {
      final notifier = container.read(restoreControllerProvider.notifier);

      expect(await notifier.applyOpened(), isNull);
      expect(restore.applied, 0);
    });

    test('open then apply keeps the summary and refreshes views', () async {
      final notifier = container.read(restoreControllerProvider.notifier);
      final tagsBefore = container.read(tagRevisionProvider);
      final albumsBefore = container.read(albumRevisionProvider);

      expect(await notifier.openArchive('secret'), isNotNull);
      final summary = await notifier.applyOpened();

      expect(summary?.tagsCreated, 2);
      expect(notifier.summary, summary);
      expect(container.read(tagRevisionProvider), tagsBefore + 1);
      expect(container.read(albumRevisionProvider), albumsBefore + 1);
      expect(container.read(restoreControllerProvider).value, isNull);
    });

    test('a wrong password gives an error state', () async {
      restore.failOpen = true;
      final notifier = container.read(restoreControllerProvider.notifier);

      expect(await notifier.openArchive('wrong'), isNull);
      expect(container.read(restoreControllerProvider).hasError, isTrue);
    });

    test('discard drops the open archive and the summary', () async {
      final notifier = container.read(restoreControllerProvider.notifier);
      await notifier.openArchive('secret');

      notifier.discard();

      expect(container.read(restoreControllerProvider).value, isNull);
      expect(notifier.summary, isNull);
    });
  });
}

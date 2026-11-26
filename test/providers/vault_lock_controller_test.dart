import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/vault/vault_auth_outcome.dart';
import 'package:in_sreerajp_imgvidgal/providers/vault_providers.dart';
import 'package:in_sreerajp_imgvidgal/repositories/vault_repository.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_auth_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_preview_backfill_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_upgrade_service.dart';

class _FakeAuthService implements VaultAuthService {
  @override
  Future<VaultAuthOutcome> unlockWithPin(
    String pin, {
    int failedAttempts = 0,
  }) async => VaultAuthOutcome.success;

  @override
  Future<VaultAuthOutcome> unlockWithPhoneLock({
    required String reason,
  }) async => VaultAuthOutcome.success;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRepository implements VaultRepository {
  int forgetCalls = 0;

  @override
  Future<void> prepareForUnlock({int? shredPasses}) async {}

  @override
  Future<void> forgetDataKey() async => forgetCalls++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUpgradeService implements VaultUpgradeService {
  int runs = 0;
  bool Function()? lastShouldContinue;
  int result = 0;

  @override
  Future<int> upgradeAll({required bool Function() shouldContinue}) async {
    runs++;
    lastShouldContinue = shouldContinue;
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeBackfill implements VaultPreviewBackfillService {
  final List<String> log;
  int result = 0;

  _FakeBackfill(this.log);

  @override
  Future<int> fillAll({required bool Function() shouldContinue}) async {
    log.add('backfill');
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeRepository repository;
  late _FakeUpgradeService upgrade;
  late bool batchRunning;
  late int convertedCallbacks;
  late VaultLockController controller;

  setUp(() {
    repository = _FakeRepository();
    upgrade = _FakeUpgradeService();
    batchRunning = false;
    convertedCallbacks = 0;
    controller = VaultLockController(
      authService: _FakeAuthService(),
      repository: repository,
      upgradeService: upgrade,
      isBatchRunning: () => batchRunning,
      onItemsConverted: () => convertedCallbacks++,
    );
  });

  tearDown(() => controller.dispose());

  test('unlocking starts the format upgrade', () async {
    await controller.unlockWithPin('1234');

    expect(upgrade.runs, 1);
    expect(upgrade.lastShouldContinue!(), isTrue);
  });

  test('the upgrade is told to stop on lock and during a batch', () async {
    await controller.unlockWithPin('1234');
    final shouldContinue = upgrade.lastShouldContinue!;

    batchRunning = true;
    expect(shouldContinue(), isFalse);

    batchRunning = false;
    controller.lock();
    expect(shouldContinue(), isFalse);
  });

  test('locking drops the data key from memory', () async {
    await controller.unlockWithPin('1234');

    controller.lock();

    expect(repository.forgetCalls, 1);
  });

  test('converted items make every view reload', () async {
    upgrade.result = 2;

    await controller.unlockWithPin('1234');
    await Future<void>.delayed(Duration.zero);

    expect(convertedCallbacks, 1);
  });

  test('nothing converted, nothing reloaded', () async {
    await controller.unlockWithPin('1234');
    await Future<void>.delayed(Duration.zero);

    expect(convertedCallbacks, 0);
  });

  test('a phone-lock unlock opens the vault like a PIN does', () async {
    await controller.unlockWithPhoneLock('Open');

    expect(controller.state.isUnlocked, isTrue);
    expect(upgrade.runs, 1);
  });

  test('missing previews are made after the format upgrade', () async {
    final log = <String>[];
    final backfill = _FakeBackfill(log)..result = 3;
    var reloads = 0;
    final withBackfill = VaultLockController(
      authService: _FakeAuthService(),
      repository: repository,
      upgradeService: _OrderedUpgrade(log),
      previewBackfill: backfill,
      onItemsConverted: () => reloads++,
    );
    addTearDown(withBackfill.dispose);

    await withBackfill.unlockWithPin('1234');
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(log, <String>['upgrade', 'backfill']);
    expect(reloads, 1);
  });
}

class _OrderedUpgrade implements VaultUpgradeService {
  final List<String> log;

  _OrderedUpgrade(this.log);

  @override
  Future<int> upgradeAll({required bool Function() shouldContinue}) async {
    log.add('upgrade');
    return 0;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
